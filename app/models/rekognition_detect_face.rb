class RekognitionDetectFace < EstablishImageProcessingPocDbConnection

  serialize :debug_data_selfie, Hash
  serialize :debug_data_document, Hash
  serialize :calculated_orientation_document, Hash
  serialize :calculated_orientation_selfie, Hash

end
