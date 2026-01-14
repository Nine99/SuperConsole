import ProjectDescription

let project = Project(
    name: "cmdCon",
    targets: [
        .target(
            name: "cmdCon",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "com.Nine99.cmdCon",
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: [],
            dependencies: [],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "A7YCA4UNT9",
                ],
                configurations: [],
                defaultSettings: .recommended
            )
        ),
    ]
)
