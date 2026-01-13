import requests
import json
import time

BASE_URL = "http://127.0.0.1:8000"

def test_constraints():
    print("--- Testing Constraints ---")
    
    # 1. Register User A
    print("\n1. Register User A (Original)")
    user_a = {
        "name": "User A",
        "username": "common_name",
        "email": "a@test.com",
        "mobile": "1111111111",
        "password": "pass",
        "role": "patient"
    }
    r1 = requests.post(f"{BASE_URL}/register", json=user_a)
    if r1.status_code == 200:
        print("[PASS] User A Registered")
    else:
        print(f"[FAIL] User A Failed: {r1.text}")

    # 2. Register User B (Same Username, Diff Email/Mobile) -> SHOULD PASS
    print("\n2. Register User B (Same Username 'common_name', Unique Email/Mobile) -> SHOULD PASS")
    user_b = {
        "name": "User B",
        "username": "common_name", # SAME
        "email": "b@test.com",     # DIFF
        "mobile": "2222222222",    # DIFF
        "password": "pass",
        "role": "patient"
    }
    r2 = requests.post(f"{BASE_URL}/register", json=user_b)
    if r2.status_code == 200:
        print("[PASS] User B Registered (Duplicate Username Allowed)")
    else:
        print(f"[FAIL] User B Failed: {r2.text}")

    # 3. Register User C (Unique Username, Duplicate Email) -> SHOULD FAIL
    print("\n3. Register User C (Unique Username, Duplicate Email 'a@test.com') -> SHOULD FAIL")
    user_c = {
        "name": "User C",
        "username": "unique_c",
        "email": "a@test.com",     # DUPLICATE (from User A)
        "mobile": "3333333333",
        "password": "pass",
        "role": "patient"
    }
    r3 = requests.post(f"{BASE_URL}/register", json=user_c)
    if r3.status_code == 400:
        print("[PASS] User C Rejected (Duplicate Email)")
    else:
        print(f"[FAIL] User C Should Fail but got: {r3.status_code} {r3.text}")

    # 4. Register User D (Unique Username, Duplicate Mobile) -> SHOULD FAIL
    print("\n4. Register User D (Unique Username, Duplicate Mobile '111...') -> SHOULD FAIL")
    user_d = {
        "name": "User D",
        "username": "unique_d",
        "email": "d@test.com",
        "mobile": "1111111111",    # DUPLICATE (from User A)
        "password": "pass",
        "role": "patient"
    }
    r4 = requests.post(f"{BASE_URL}/register", json=user_d)
    if r4.status_code == 400:
        print("[PASS] User D Rejected (Duplicate Mobile)")
    else:
        print(f"[FAIL] User D Should Fail but got: {r4.status_code} {r4.text}")

if __name__ == "__main__":
    try:
        test_constraints()
    except Exception as e:
        print(f"Error: {e}")
