class AwsDetectLabel < EstablishImageProcessingPocDbConnection

  serialize :document_id_labels, Hash
  serialize :selfie_labels, Hash
end
