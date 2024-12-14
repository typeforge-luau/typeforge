--!strict

type function one(arg)
    return types.singleton("one")
end

type function two(arg)
    return one(arg)
end

type function main()
    return two("hello")
end

type test = main