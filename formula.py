N = 8

MAX_VAL =  (1 << (N - 1)) - 1
MIN_VAL = -(1 << (N - 1))

def find_q(a, b, c, d):

    sub1 = a - b
    add1 = 1 + (3 * c)
    mul3 = 4 * d

    sub2 = (sub1 * add1) - mul3

    div = sub2 >> 1

    if div > MAX_VAL:
        saturated_q = MAX_VAL
    elif div < MIN_VAL:
        saturated_q = MIN_VAL
    else:
        saturated_q = int(div)

    return saturated_q

if __name__ == "__main__":
    test_cases = [
        {"name": "Test 1: Simple values", "a": 1, "b": 2, "c": 3, "d": 4},
        {"name": "Test 2: Simple values", "a": 10, "b": 20, "c": 5, "d": 10},
        {"name": "Test 3: Negative numbers", "a": -5, "b": 10, "c": -20, "d": -1},
        {"name": "Test 4: Positive overflow", "a": 120, "b": -25, "c": 7, "d": 6},
        {"name": "Test 5: Negative overflow", "a": -120, "b": 25, "c": 7, "d": 6},
        {"name": "Test 6: Zero values", "a": 0, "b": 0, "c": 0, "d": 0},
        {"name": "Test 7: Max and min inputs", "a": 127, "b": -128, "c": 127, "d": -128},
    ] # More tests are needed

    for test in test_cases:
        q = find_q(test["a"], test["b"], test["c"], test["d"])
        print(f"{test['name']}:")
        print(f"a={test['a']}, b={test['b']}, c={test['c']}, d={test['d']}")
        print(f"q={q}")
