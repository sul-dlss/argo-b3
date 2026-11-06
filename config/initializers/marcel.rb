# frozen_string_literal: true

# Marcel does not otherwise recognize GLB (binary glTF) files, which are the model files of 3d objects.
Marcel::MimeType.extend 'model/gltf-binary', extensions: %w[glb], magic: [[0, 'glTF']]

# Marcel does not otherwise recognize FlatGeobuf files, a geo vector format.
Marcel::MimeType.extend 'application/vnd.fgb', extensions: %w[fgb], magic: [[0, "fgb\x03fgb"]]

# Marcel does not otherwise recognize PMTiles files, a geo tile archive format.
Marcel::MimeType.extend 'application/vnd.pmtiles', extensions: %w[pmtiles], magic: [[0, 'PMTiles']]

# Types decided by extension alone, since magic would mistype or miss them: GDAL overviews (.ovr) are TIFFs,
# .shp and .shx share magic, and .prj (projection) files are text without magic.
module ExtensionMimeTypes
  TYPES = {
    '.ovr' => 'application/octet-stream',
    '.shp' => 'application/vnd.shp',
    '.shx' => 'application/octet-stream',
    '.prj' => 'text/plain'
  }.freeze

  def for(pathname_or_io = nil, name: nil, extension: nil, declared_type: nil)
    filename = name || (pathname_or_io.to_s if pathname_or_io.is_a?(Pathname))
    ext = extension ? ".#{extension.to_s.delete_prefix('.')}" : File.extname(filename.to_s)
    TYPES.fetch(ext.downcase) { super }
  end
end
Marcel::MimeType.singleton_class.prepend ExtensionMimeTypes
