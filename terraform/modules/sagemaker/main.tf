resource "aws_sagemaker_domain" "main" {
  domain_name = var.domain_name
  auth_mode   = var.auth_mode
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role = var.execution_role_arn
    security_groups = var.security_group_ids

    # Jupyter Server App Settings
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type        = var.default_instance_type
        sagemaker_image_arn  = var.jupyter_server_image_arn
      }

      code_repository {
        repository_url = var.code_repository_url
      }
    }

    # Kernel Gateway App Settings
    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type       = var.default_instance_type
        sagemaker_image_arn = var.kernel_gateway_image_arn
      }

      custom_image {
        image_name         = "security-ml-kernel"
        app_image_config_name = aws_sagemaker_app_image_config.security_kernel.app_image_config_name
      }
    }

    # Sharing Settings
    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path        = "s3://${var.notebooks_bucket}/shared-notebooks"
      s3_kms_key_id         = var.kms_key_id
    }

    # Canvas App Settings for ML model building
    canvas_app_settings {
      time_series_forecasting_settings {
        status = "ENABLED"
      }

      model_register_settings {
        status = "ENABLED"
      }
    }

    # Studio Web Portal Settings
    r_studio_server_pro_app_settings {
      access_status = "DISABLED"  # Enable if using RStudio
    }
  }

  default_space_settings {
    execution_role = var.execution_role_arn

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = var.default_instance_type
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = var.default_instance_type
      }
    }
  }

  # Encryption
  kms_key_id = var.kms_key_id

  # Domain retention policy
  retention_policy {
    home_efs_file_system = "Delete"  # Change to "Retain" for production
  }

  tags = merge(
    var.tags,
    {
      Name = var.domain_name
    }
  )
}

# Custom kernel image config for security tools
resource "aws_sagemaker_app_image_config" "security_kernel" {
  app_image_config_name = "security-ml-kernel-config"

  kernel_gateway_image_config {
    kernel_spec {
      name         = "python3"
      display_name = "Security ML Python 3"
    }

    file_system_config {
      default_gid = 100
      default_uid = 1000
      mount_path  = "/home/sagemaker-user"
    }
  }

  tags = var.tags
}

# User profiles for security team members
resource "aws_sagemaker_user_profile" "security_analysts" {
  for_each = var.security_team_users

  domain_id         = aws_sagemaker_domain.main.id
  user_profile_name = each.key

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = var.security_group_ids

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = each.value.instance_type != null ? each.value.instance_type : var.default_instance_type
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = each.value.instance_type != null ? each.value.instance_type : var.default_instance_type
      }
    }

    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path        = "s3://${var.notebooks_bucket}/user-notebooks/${each.key}"
      s3_kms_key_id         = var.kms_key_id
    }
  }

  tags = merge(
    var.tags,
    {
      User = each.key
      Team = each.value.team
    }
  )
}

# Space for collaborative work
resource "aws_sagemaker_space" "threat_hunting" {
  domain_id  = aws_sagemaker_domain.main.id
  space_name = "threat-hunting-space"

  space_settings {
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.xlarge"
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.xlarge"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Purpose = "ThreatHunting"
    }
  )
}

resource "aws_sagemaker_space" "incident_response" {
  domain_id  = aws_sagemaker_domain.main.id
  space_name = "incident-response-space"

  space_settings {
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.xlarge"
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.xlarge"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Purpose = "IncidentResponse"
    }
  )
}

# Lifecycle configuration for installing security tools
resource "aws_sagemaker_studio_lifecycle_config" "security_tools" {
  studio_lifecycle_config_name     = "install-security-tools"
  studio_lifecycle_config_app_type = "JupyterServer"

  studio_lifecycle_config_content = base64encode(templatefile("${path.module}/scripts/install-security-tools.sh", {
    notebooks_bucket = var.notebooks_bucket
    data_bucket      = var.data_bucket
  }))
}
