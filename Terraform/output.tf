 output "server_private_ip" {
   value = aws_instance.wordpress.private_ip

 }

 output "server_id" {
   value = aws_instance.wordpress.id
 }

  output "server_public_ip" {
   value = aws_eip.eip.public_ip
 }