using Documenter, ESDLHelpers

makedocs(;
    modules=[ESDLHelpers],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/felixcremer/ESDLHelpers.jl/blob/{commit}{path}#L{line}",
    sitename="ESDLHelpers.jl",
    authors="Felix Cremer",
    assets=String[],
)

deploydocs(;
    repo="github.com/felixcremer/ESDLHelpers.jl",
)
