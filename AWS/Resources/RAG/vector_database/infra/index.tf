resource "opensearch_index" "this" {
  name = "faqs"
  index_knn = true
  mappings = jsonencode({
        "properties": {
            "text": {
                "type": "text"
            },
            "embedding": {
                "type": "knn_vector",
                "dimension": 512
            }
        }
    })
}