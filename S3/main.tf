resource "aws_s3_bucket" "srushs3buckets3bucket" {

	bucket = "${var.bucket_name}"
	acl = "private"

	versioning {
		enabled = true
	}
}