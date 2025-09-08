from app.utils import ModelType
from app.utils.enums import ModuleName, ModuleProgress

# Module scripts for step-by-step execution
MODULE_SCRIPTS = {
    ModuleProgress.init_module: "r_scripts/r_models/00_common_setup.R",
    ModuleProgress.load_module: "r_scripts/r_models/01_data_module.R",
    ModuleProgress.describe_module: "r_scripts/r_models/02_describe_module.R",
    ModuleProgress.estimate_module: "r_scripts/r_models/03_estimate_module.R",
    ModuleProgress.validate_module: "r_scripts/r_models/04_validate_module.R",
    ModuleProgress.risk_map_module: "r_scripts/r_models/05_riskmap_module.R",
}

# Common setup script that runs before all modules
COMMON_SETUP_SCRIPT = "r_scripts/r_models/00_common_setup.R"

# Legacy model scripts (keeping for backward compatibility)
MODEL_SCRIPTS = {
    ModelType.Model1_Simple: "r_scripts/r_models/model_1.R",
    ModelType.Model2_Autoregressive: "r_scripts/r_models/model_2.R",
    ModelType.Model3_MB_User: "r_scripts/r_models/model_3.R",
    ModelType.Model4_UHI: "r_scripts/r_models/model_4.R",
    ModelType.Model5_RAB: "r_scripts/r_models/model_5.R",
    ModelType.Model6_HSDPD_user: "r_scripts/r_models/model_6.R",
}

# Module execution order
MODULE_EXECUTION_ORDER = [
    ModuleProgress.init_module,
    ModuleProgress.load_module,
    ModuleProgress.describe_module,
    ModuleProgress.estimate_module,
    ModuleProgress.validate_module,
    ModuleProgress.risk_map_module,
]
