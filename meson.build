# Project name, programming language and version
project (
    'hr.from.josipantolis.life',
    'c', 'vala',
    version: '0.1.0'
)

# Translation module
i18n = import ('i18n')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

# Listing dependencies
dependencies = [
    dependency ('gsl'),
    dependency ('granite'),
    dependency ('gtk+-3.0'),
    dependency ('gee-0.8'),
    dependency ('libhandy-1'),
    meson.get_compiler('c').find_library('m', required: false),
]

subdir ('data')
subdir ('src')
subdir ('test')
subdir ('po')

# Defining executable
executable (
    meson.project_name (),
    sources,
    gresource,
    dependencies: dependencies,
    install: true
)

# Defning tests executable
test('tests', executable (
    meson.project_name () + '-tests',
    common_sources + test_sources,
    dependencies: dependencies
))

meson.add_install_script('meson/post_install.py')
