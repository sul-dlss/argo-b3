# frozen_string_literal: true

# Marcel does not otherwise recognize GLB (binary glTF) files, which are the model files of 3d objects.
Marcel::MimeType.extend 'model/gltf-binary', extensions: %w[glb], magic: [[0, 'glTF']]
