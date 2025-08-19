resource "opensearch_index" "vector_database" {
  name      = "faqs"
  index_knn = true
  mappings = jsonencode({
    "properties" : {
      "text" : {
        "type" : "text"
      },
      "embedding" : {
        "type" : "knn_vector",
        "dimension" : 512
      }
    }
  })
  force_destroy = true
}