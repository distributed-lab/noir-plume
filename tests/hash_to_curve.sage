load('constants.sage')

# Get msg in byte format
def HashToCurve(msg):
    u = HashToField(msg)

    q0 = MapToCurve(u[0])
    q1 = MapTocurve(u[1])

    return E(IsoMap(q0)) + E(IsoMap(q1))
