def invmod(a,b):
    """
    Return modular inverse using a version Euclid's Algorithm
    Code by Andrew Kuchling in Python Journal:
    http://www.pythonjournal.com/volume1/issue1/art-algorithms/
    -- in turn also based on Knuth, vol 2.
    """
    a1, a2, a3 = 1L,0L,a
    b1, b2, b3 = 0L,1L,b
    while b3 != 0:
        # The following division will drop decimals.

        q = a3 / b3  
        t = a1 - b1*q, a2 - b2*q, a3 - b3*q
        a1, a2, a3 = b1, b2, b3
        b1, b2, b3 = t
    while a2<0: a2 = a2 + a
    return a2
