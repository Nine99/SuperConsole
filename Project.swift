import ProjectDescription

let project = Project(
    name: "superCon",
    targets: [
        .target(
            name: "superCon",
            destinations: .iOS,
            product: .app,
            bundleId: "com.Nine99.superCon",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["superCon/Sources/**"],
            resources: ["superCon/Resources/**"],
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
        .target(
            name: "superConTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.Nine99.superConTests",
            infoPlist: .default,
            sources: ["superCon/Tests/**"],
            resources: [],
            dependencies: [.target(name: "superCon")],
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
