# Compile static resources
gnome = import ('gnome')

gresource = gnome.compile_resources (
    'gresource',
    'gresource.xml',
    source_dir: 'data'
)

# Translate and install our .desktop file so the Applications Menu will see it
i18n.merge_file (
    input: 'life.desktop.in',
    output: meson.project_name () + '.desktop',
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'applications')
)

# Translate and install our .appdata.xml file so AppCenter will see it
i18n.merge_file (
    input: 'life.appdata.xml.in',
    output: meson.project_name () + '.appdata.xml',
    po_dir: join_paths (meson.source_root (), 'po', 'extra'),
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'metainfo')
)

# Install GSchema file
install_data (
    'gschema.xml',
    rename: meson.project_name () + '.gschema.xml',
    install_dir: join_paths (get_option ('datadir'), 'glib-2.0', 'schemas')
)
