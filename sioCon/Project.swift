import ProjectDescription

let project = Project(
    name: "sioCon",
    targets: [
        .target(
            name: "sioCon",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "com.Nine99.sioCon",
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
