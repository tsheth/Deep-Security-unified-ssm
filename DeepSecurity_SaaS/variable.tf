variable "AWS_ACCESS_KEY" {
  default = "AKIAITESB3AMEJOKNRQA"
}

variable "AWS_SECRET_KEY" {
  default = "PdL0ByU/sBBLE+IxY86rQvxz6as1OVEOu9PBzXeJ"
}

variable "AWS_REGION" {
  default = "us-east-2"
}

variable "EC2_tag_key" {
  description = "Enter EC2 Tag Key that has to be searched for installing agent:"
  default     = "DSADeploy"
}

variable "EC2_tag_value" {
  description = "Enter EC2 Tag Value that has to be searched for installing agent:"
  default     = "yes"
}

variable "DSM_URL" {
  description = "Enter Deep Security manager URL for Dashboard:"
  default     = "app.deepsecurity.trendmicro.com"
}

variable "DSA_URL" {
  description = "Enter Deep Security agent activation:"
  default     = "agents.deepsecurity.trendmicro.com"
}

variable "DSA_Activation_Port" {
  description = "Enter Deep Security agent activation port(default 443):"
  default     = "443"
}

variable "DSM_Tenent_ID" {
  description = "Enter Deep Security tenet ID (Required):"
  default     = "0FA59FB6-961A-A931-C955-FA7258C3C898"
}

variable "Tenent_Token" {
  description = "Enter Deep Security Token for tenent(Required):"
  default     = "4FD7E8A2-9B90-83A2-2185-D5D1AC788747"
}

variable "Default_policyNo_windows" {
  description = "Enter Default Linux policy no (default 1):"
}

variable "Default_policyNo_linux" {
  description = "Enter Default Windows policy no (default 1):"
}

