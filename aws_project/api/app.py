import os

from flask import Flask, jsonify, request
from flask_restful import Api, Resource
import psycopg
from psycopg.conninfo import make_conninfo
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool, PoolTimeout
import bcrypt

app = Flask(__name__)
api = Api(app)
# Connection settings as separate variables: on AWS the password comes from
# a secret and is injected by ECS as its own variable, the host from Terraform.
DB_CONNINFO = make_conninfo(
    host=os.environ["DB_HOST"],
    port=os.environ.get("DB_PORT", "5432"),
    dbname=os.environ.get("DB_NAME", "bankapi"),
    user=os.environ["DB_USER"],
    password=os.environ["DB_PASSWORD"],
    # TLS by default (RDS); set DB_SSLMODE=disable only for a local database
    sslmode=os.environ.get("DB_SSLMODE", "require"),
)

pool = ConnectionPool(
    DB_CONNINFO,
    min_size=1,
    max_size=5,
    timeout=3,
    kwargs={"autocommit": True, "row_factory": dict_row, "connect_timeout": 2},
    check=ConnectionPool.check_connection,
    open=False,
)
pool.open(wait=False)

def fetchOne(sql, params=()):
    # take a connection from the pool, run the query, give the connection back
    with pool.connection() as conn:
        return conn.execute(sql, params).fetchone()

def execute(sql, params=()):
    with pool.connection() as conn:
        conn.execute(sql, params)

def UserExist(username):
    if fetchOne("SELECT 1 FROM users WHERE username = %s", (username,)) is not None:
        return True
    return False

class Register(Resource):
    def post(self):
        postedData = request.get_json()
        username = postedData["username"]
        password = postedData["password"]

        if UserExist(username):
            return generateReturnDictionary(409, "Invalid username")
        hashed_pw = bcrypt.hashpw(password.encode('utf8'), bcrypt.gensalt())

        execute(
            "INSERT INTO users (username, password, own, debt) VALUES (%s, %s, 0, 0)",
            (username, hashed_pw),
        )
        return generateReturnDictionary(200, "You successfully signed up for the API")
    
def verifyPw(username, password):
    if not UserExist(username):
        return False
    hashed_pw = fetchOne(
        "SELECT password FROM users WHERE username = %s", (username,)
    )["password"]
    if bcrypt.hashpw(password.encode('utf8'), hashed_pw) == hashed_pw:
        return True
    else:        
        return False
        
def cashWithUser(username):
    cash = fetchOne("SELECT own FROM users WHERE username = %s", (username,))["own"]
    return cash
    
def debtWithUser(username):
    debt = fetchOne("SELECT debt FROM users WHERE username = %s", (username,))["debt"]
    return debt
    
def generateReturnDictionary(status,msg):
    retJson = {
        "status": status,
        "msg": msg
    }
    return retJson, status
    
def verifyCredentials(username, password):
    if not UserExist(username):
        return generateReturnDictionary(401, "Invalid username"), True
        
    correct_pw = verifyPw(username, password)
    if not correct_pw:
        return generateReturnDictionary(401, "Invalid password"), True
    return None, False
    
def updateAccount(username, balance):
    execute("UPDATE users SET own = %s WHERE username = %s", (balance, username))

def updateDebt(username, balance):
    execute("UPDATE users SET debt = %s WHERE username = %s", (balance, username))


class Health(Resource):
    def get(self):
        try:
            with pool.connection(timeout=2) as conn:
                conn.execute("SELECT 1")
        except (psycopg.Error, PoolTimeout):
            return {"status": "error"}, 503
        return {"status": "ok"}, 200


class Add(Resource):
    def post(self):
        postedData = request.get_json()
        username = postedData["username"]

        password = postedData["password"]
        amount = postedData["amount"]

        retJson, error = verifyCredentials(username, password)
        if error:
            return retJson
        
        if amount <= 0:
            return generateReturnDictionary(400, "The money amount entered must be positive!")

        cash = cashWithUser(username)
        
        amount -=1
        bank_cash = cashWithUser("BANK")
        updateAccount("BANK", bank_cash + 1)
        updateAccount(username, cash + amount)

        return generateReturnDictionary(200, "Amount added successfully to account")



class Transfer(Resource):
    def post(self):
        postedData = request.get_json()
        username = postedData["username"]
        password = postedData["password"]
        to = postedData["to"]
        money = postedData["amount"]

        retJson, error = verifyCredentials(username, password)
        if error:
            return retJson
        
        cash = cashWithUser(username)
        if cash <= 0:
            return generateReturnDictionary(400, "You`re out of money, please add or take a loan")

        if not UserExist(to):
            return generateReturnDictionary(404, "Receiver username is invalid")
        
        cash_from = cashWithUser(username)
        cash_to = cashWithUser(to)
        bank_cash = cashWithUser("BANK")
        updateAccount("BANK", bank_cash + 1)
        updateAccount(to, cash_to + money - 1)
        updateAccount(username, cash_from - money)

        return generateReturnDictionary(200, "Amount transferred successfully")
    
class Balance(Resource):
    def post(self):
        postedData = request.get_json()
        username = postedData["username"]
        password = postedData["password"]
        retJson, error = verifyCredentials(username, password)
        if error:
            return retJson
        
        retJson = fetchOne(
            'SELECT username AS "Username", own AS "Own", debt AS "Debt" FROM users WHERE username = %s',
            (username,),
        )

        return jsonify(retJson)
    
class TakeLoan(Resource):
    def post(self):
        postedData = request.get_json()

        username = postedData["username"]
        password = postedData["password"]
        money = postedData["amount"]

        retJson, error = verifyCredentials(username, password)

        if error:
            return retJson
        cash = cashWithUser(username)
        debt = debtWithUser(username)
        updateAccount(username, cash + money)
        updateDebt(username, debt + money)
        return generateReturnDictionary(200, "Loan added successfully!")
    

class PayLoan(Resource):
    def post(self):
        postedData = request.get_json()

        username = postedData["username"]
        password = postedData["password"]
        money = postedData["amount"]

        retJson, error = verifyCredentials(username, password)
        if error:
            return retJson
        
        cash = cashWithUser(username)
        if cash < money:
            return generateReturnDictionary(400, "You don`t have enough money to pay the loan!")
        
        debt = debtWithUser(username)
        updateAccount(username, cash - money)
        updateDebt(username, debt - money)

        return generateReturnDictionary(200, "Loan paid successfully!")


api.add_resource(Health, "/api/health")
api.add_resource(Register, "/api/register")
api.add_resource(Add, "/api/add")
api.add_resource(Transfer, "/api/transfer")
api.add_resource(Balance, "/api/balance")
api.add_resource(TakeLoan, "/api/take_loan")
api.add_resource(PayLoan, "/api/pay_loan")

if __name__ == "__main__":
    app.run(host='0.0.0.0', debug=os.environ.get("FLASK_DEBUG") == "1")
