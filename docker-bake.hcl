variable "USERNAME" {
    default = "spinnernicholas"
}

variable "APP" {
    default = "open-sora"
}

variable "RELEASE" {
    default = "0.0.1"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["${USERNAME}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
    }
}