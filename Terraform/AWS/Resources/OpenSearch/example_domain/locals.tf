locals {
  current-ip = chomp(data.http.checkip.body)
}
