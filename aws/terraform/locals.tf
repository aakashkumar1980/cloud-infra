locals {
  project = {
    namespace = "_terraform",
    mime_types = jsondecode(file("${path.module}/../../_sample-data/mime.json"))
  }
}
