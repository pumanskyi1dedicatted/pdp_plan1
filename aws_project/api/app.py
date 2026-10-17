import functools
import logging
import os

import bcrypt
from flask import Flask, request
from flask_restful import Api, Resource
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError, PyMongoError

# --- Configuration (12-factor: everything comes from the environment) ---
MONGO_URL = os.environ["MONGO_URL"]
MONGO_DB = os.environ.get("MONGO_DB", "BankAPI")
BANK_ACCOUNT = "BANK"
FEE = 1

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger("bankapi")

app = Flask(__name__)
api = Api(app)

# Fail fast instead of hanging 30s when the database is unreachable.
client = MongoClient(MONGO_URL, serverSelectionTimeoutMS=2000)
users = client[MONGO_DB]["Users"]

# A unique index makes duplicate usernames impossible even under concurrent
# requests. Startup must not crash if the database is briefly unavailable.
try:
    users.create_index("Username", unique=True)
except PyMongoError as exc:
    log.warning("Could not ensure the Username index at startup: %s", exc)


# --- Helpers ---
def reply(code, msg):
    """Same HTTP code in the response and in the body (for old clients)."""
    return {"status": code, "msg": msg}, code


def is_non_empty_str(value):
    return isinstance(value, str) and value.strip() != ""


def parse_amount(value):
    """Amounts are positive integers; booleans are rejected explicitly."""
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        return None
    return value


def get_fields(*names):
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return None, reply(400, "Request body must be a JSON object")
    missing = [name for name in names if name not in data]
    if missing:
        return None, reply(400, f"Missing fields: {', '.join(missing)}")
    return data, None


def authenticate(username, password):
    if not is_non_empty_str(username) or not is_non_empty_str(password):
        return None
    user = users.find_one({"Username": username})
    if user is None or "Password" not in user:
        return None
    if not bcrypt.checkpw(password.encode("utf-8"), user["Password"]):
        return None
    return user


def authorized_request(*extra_fields):
    """Validate the body and credentials. Returns (data, user, error)."""
    data, error = get_fields("username", "password", *extra_fields)
    if error:
        return None, None, error
    user = authenticate(data["username"], data["password"])
    if user is None:
        # One message for both cases, so usernames cannot be enumerated.
        return None, None, reply(401, "Invalid username or password")
    return data, user, None


def collect_fee():
    # upsert creates the BANK account on an empty database.
    users.update_one(
        {"Username": BANK_ACCOUNT},
        {"$inc": {"Own": FEE}, "$setOnInsert": {"Debt": 0}},
        upsert=True,
    )


def handle_db_errors(func):
    """A database outage is a temporary condition: 503, not a crash with 500."""

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except PyMongoError as exc:
            log.error("Database error: %s", exc)
            return reply(503, "Service temporarily unavailable")

    return wrapper


class BaseResource(Resource):
    method_decorators = [handle_db_errors]


# --- Endpoints ---
class Health(Resource):
    def get(self):
        try:
            client.admin.command("ping")
        except PyMongoError as exc:
            log.error("Health check failed: %s", exc)
            return {"status": "error"}, 503
        return {"status": "ok"}, 200


class Register(BaseResource):
    def post(self):
        data, error = get_fields("username", "password")
        if error:
            return error
        username, password = data["username"], data["password"]
        if not is_non_empty_str(username) or not is_non_empty_str(password):
            return reply(400, "Username and password must be non-empty strings")
        if username == BANK_ACCOUNT or users.find_one({"Username": username}):
            return reply(409, "Username is not available")

        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
        try:
            users.insert_one(
                {"Username": username, "Password": hashed, "Own": 0, "Debt": 0}
            )
        except DuplicateKeyError:
            return reply(409, "Username is not available")
        return reply(201, "Account created")


class Add(BaseResource):
    def post(self):
        data, user, error = authorized_request("amount")
        if error:
            return error
        amount = parse_amount(data["amount"])
        if amount is None:
            return reply(400, "Amount must be a positive integer")

        # $inc is atomic: no lost updates under concurrent requests.
        users.update_one(
            {"Username": user["Username"]}, {"$inc": {"Own": amount - FEE}}
        )
        collect_fee()
        return reply(200, "Amount added to account")


class Transfer(BaseResource):
    def post(self):
        data, user, error = authorized_request("to", "amount")
        if error:
            return error
        amount = parse_amount(data["amount"])
        if amount is None:
            return reply(400, "Amount must be a positive integer")
        to = data["to"]
        if not is_non_empty_str(to) or to in (BANK_ACCOUNT, user["Username"]):
            return reply(400, "Invalid recipient")
        if users.find_one({"Username": to}) is None:
            return reply(404, "Recipient not found")

        # Debit only if the balance covers the amount, in one atomic operation.
        debit = users.update_one(
            {"Username": user["Username"], "Own": {"$gte": amount}},
            {"$inc": {"Own": -amount}},
        )
        if debit.modified_count == 0:
            return reply(400, "Insufficient funds")
        # Note: without a replica set MongoDB has no multi-document
        # transactions, so these steps are not atomic as a whole.
        users.update_one({"Username": to}, {"$inc": {"Own": amount - FEE}})
        collect_fee()
        return reply(200, "Amount transferred")


class Balance(BaseResource):
    def post(self):
        _, user, error = authorized_request()
        if error:
            return error
        return {
            "Username": user["Username"],
            "Own": user.get("Own", 0),
            "Debt": user.get("Debt", 0),
        }, 200


class TakeLoan(BaseResource):
    def post(self):
        data, user, error = authorized_request("amount")
        if error:
            return error
        amount = parse_amount(data["amount"])
        if amount is None:
            return reply(400, "Amount must be a positive integer")

        users.update_one(
            {"Username": user["Username"]},
            {"$inc": {"Own": amount, "Debt": amount}},
        )
        return reply(200, "Loan added")


class PayLoan(BaseResource):
    def post(self):
        data, user, error = authorized_request("amount")
        if error:
            return error
        amount = parse_amount(data["amount"])
        if amount is None:
            return reply(400, "Amount must be a positive integer")

        result = users.update_one(
            {
                "Username": user["Username"],
                "Own": {"$gte": amount},
                "Debt": {"$gte": amount},
            },
            {"$inc": {"Own": -amount, "Debt": -amount}},
        )
        if result.modified_count == 0:
            return reply(400, "Insufficient funds or amount exceeds the debt")
        return reply(200, "Loan repaid")


api.add_resource(Health, "/api/health")
api.add_resource(Register, "/api/register")
api.add_resource(Add, "/api/add")
api.add_resource(Transfer, "/api/transfer")
api.add_resource(Balance, "/api/balance")
api.add_resource(TakeLoan, "/api/take_loan")
api.add_resource(PayLoan, "/api/pay_loan")


# Local development only. In containers the app is started by gunicorn,
# which imports `app` directly, so this block never runs there.
if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=int(os.environ.get("PORT", "5000")),
        debug=os.environ.get("FLASK_DEBUG") == "1",
    )
