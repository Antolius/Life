# Populate constants with meson build data
build_info = configuration_data ()
build_info.set_quoted('PROJECT_NAME', meson.project_name())
build_info.set_quoted('VERSION', meson.project_version())

build_constants = configure_file (
    input: join_paths ('Constants', 'Build.vala.in'),
    output: 'Build.vala',
    configuration: build_info
)

sources = files (
    'Application.vala',
    'MainWindow.vala',
    'Simulation.vala',
    'Ticker.vala',
    'Widgets/BoardGrid.vala',
    'Widgets/HeaderBar.vala',
    'Constants/Const.vala'
)

sources += build_constants
