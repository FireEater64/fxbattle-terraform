output "elastic ip" {
  value = "${aws_eip.fxbattle.public_ip}"
}