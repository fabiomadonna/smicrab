import os
from app.domain.validate.validate_dto import (
    GetValidateOutputsResponse,
    ValidateModuleOutputs,
    ResidualSummaryStatistics,
    AutocorrelationTests,
    NormalityTests,
    BootstrapValidation,
    BootstrapComparison,
    ParameterDistribution,
    ValidateModuleFile,
    ModelSpecificAvailabilitySet,
)
from app.utils.enums import ModelType
from app.utils.logger import Logger
from app.utils.utils import get_analysis_output_path
from app.Models.analysis import Analysis

class ValidateModuleService:
    def __init__(self):
        pass

    async def get_validate_outputs(
        self, analysis: Analysis
    ) -> GetValidateOutputsResponse:
        """Get validate module outputs for the given analysis and model type."""
        try:
            # Get output directory path
            output_dir = get_analysis_output_path(analysis.id, analysis.model_type)
            
            # Generate outputs
            outputs = self._generate_validate_outputs(output_dir, analysis.model_type)
            
            # Generate model specific availability
            model_availability = ModelSpecificAvailabilitySet()
            
            return GetValidateOutputsResponse(
                validate_module_outputs=outputs,
                model_specific_availability=model_availability
            )
            
        except Exception as e:
            Logger.error(
                f"Failed to get validate outputs: {e}",
                context={
                    "task": "get_validate_outputs",
                    "analysis_id": analysis.id,
                    "model_type": analysis.model_type.value
                }
            )
            raise

    def _generate_validate_outputs(
        self, output_dir: str, model_type: ModelType
    ) -> ValidateModuleOutputs:
        """Generate validate module outputs based on configuration."""
        
        # Residual Summary Statistics
        residual_summary_statistics = ResidualSummaryStatistics(
            description="Summary statistics plots for residual analysis (mean, sd, skewness, kurtosis)",
            files=[
                ValidateModuleFile(
                    name="residual_mean",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_mean.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_mean.png"),
                    function="fun.plot.stat.RESIDs(df.results.estimate, statistic=mean, title='mean', na.rm=TRUE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Mean of residuals spatial plot"
                ),
                ValidateModuleFile(
                    name="residual_sd",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_sd.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_sd.png"),
                    function="fun.plot.stat.RESIDs(df.results.estimate, statistic=sd, title='sd', na.rm=TRUE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Standard deviation of residuals spatial plot"
                ),
                ValidateModuleFile(
                    name="residual_skewness",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_skewness.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_skewness.png"),
                    function="fun.plot.stat.RESIDs(df.results.estimate, statistic=skewness, title='skewness', na.rm=TRUE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Skewness of residuals spatial plot"
                ),
                ValidateModuleFile(
                    name="residual_kurtosis",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_kurtosis.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_kurtosis.png"),
                    function="fun.plot.stat.RESIDs(df.results.estimate, statistic=kurtosis, title='kurtosis', na.rm=TRUE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Kurtosis of residuals spatial plot"
                )
            ]
        )
        
        # Autocorrelation Tests
        autocorrelation_tests = AutocorrelationTests(
            description="Ljung-Box autocorrelation test results with and without Benjamini-Yekutieli adjustment",
            files=[
                ValidateModuleFile(
                    name="ljung_box_test",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_LBtest_not_adjusted.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_LBtest_not_adjusted.png"),
                    function="fun.plot.stat.discrete.RESIDs(df.results.estimate, title='Ljung-Box\\nautocorrelation\\ntest', statistic=fun.LBtest, alpha=pars_alpha, significant.test=TRUE, BYadjusted=FALSE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Ljung-Box autocorrelation test without Benjamini-Yekutieli adjustment"
                ),
                ValidateModuleFile(
                    name="ljung_box_test_by_adjusted",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_LBtest_BYadjusted.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_LBtest_BYadjusted.png"),
                    function="fun.plot.stat.discrete.RESIDs(df.results.estimate, title='Ljung-Box\\nautocorrelation\\ntest', statistic=fun.LBtest, alpha=pars_alpha, significant.test=TRUE, BYadjusted=TRUE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Ljung-Box autocorrelation test with Benjamini-Yekutieli adjustment"
                )
            ]
        )
        
        # Normality Tests
        normality_tests = NormalityTests(
            description="Jarque-Bera normality test results with and without Benjamini-Yekutieli adjustment",
            files=[
                ValidateModuleFile(
                    name="jarque_bera_test",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_JBtest_not_adjusted.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_JBtest_not_adjusted.png"),
                    function="fun.plot.stat.discrete.RESIDs(df.results.estimate, title='Jarque-Bera\\nnormality\\ntest', statistic=fun.JBtest, alpha=pars_alpha, significant.test=TRUE, BYadjusted=FALSE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Jarque-Bera normality test without Benjamini-Yekutieli adjustment"
                ),
                ValidateModuleFile(
                    name="jarque_bera_test_by_adjusted",
                    path_dynamic=os.path.join(output_dir, "validate/plots/residual_JBtest_BYadjusted.html"),
                    path_static=os.path.join(output_dir, "validate/plots/residual_JBtest_BYadjusted.png"),
                    function="fun.plot.stat.discrete.RESIDs(df.results.estimate, title='Jarque-Bera\\nnormality\\ntest', statistic=fun.JBtest, alpha=pars_alpha, significant.test=TRUE, BYadjusted=TRUE, pars=pars_list, bool_dynamic=bool_dynamic, output_path=output_path)",
                    description="Jarque-Bera normality test with Benjamini-Yekutieli adjustment"
                )
            ]
        )
        
        # Bootstrap Validation (for H-SDPD models)
        bootstrap_comparison = BootstrapComparison(
            description="Bootstrap comparison between observed and bootstrap time series",
            files=[
                ValidateModuleFile(
                    name="bootstrap_mean_comparison",
                    path_dynamic=os.path.join(output_dir, "bootstrap/plots/coeffboot_mean.html"),
                    path_static=os.path.join(output_dir, "bootstrap/plots/coeffboot_mean.png"),
                    function="fun.plot.coeffboot.TEST(df.results.test, alpha=pars_alpha, matrix1='means.tsboot', pars=pars_list)[[2]]",
                    description="Mean of differences between bootstrap and observed time series"
                ),
                ValidateModuleFile(
                    name="bootstrap_sd_comparison",
                    path_dynamic=os.path.join(output_dir, "bootstrap/plots/coeffboot_sd.html"),
                    path_static=os.path.join(output_dir, "bootstrap/plots/coeffboot_sd.png"),
                    function="fun.plot.coeffboot.TEST(df.results.test, alpha=pars_alpha, matrix1='sdevs.tsboot', pars=pars_list)[[2]]",
                    description="Standard deviation of differences between bootstrap and observed time series"
                )
            ]
        )
        
        parameter_distribution = ParameterDistribution(
            description="Bootstrap distribution of parameter estimators",
            files=[
                ValidateModuleFile(
                    name="bootstrap_significance",
                    path_dynamic=os.path.join(output_dir, "bootstrap/plots/coeff_hat.html"),
                    path_static=os.path.join(output_dir, "bootstrap/plots/coeff_hat.png"),
                    function="fun.plot.coeffboot.TEST(df.results.test, alpha=pars_alpha, matrix1='coeff.hat', matrix2='pvalue.test', pars=pars_list)[[user_coeff_choice]]",
                    description="Bootstrap significance test with p-values for selected parameter"
                ),
                ValidateModuleFile(
                    name="bootstrap_bias",
                    path_dynamic=os.path.join(output_dir, "bootstrap/plots/coeff_bias_boot.html"),
                    path_static=os.path.join(output_dir, "bootstrap/plots/coeff_bias_boot.png"),
                    function="fun.plot.coeffboot.TEST(df.results.test, alpha=pars_alpha, matrix1='coeff.bias.boot', pars=pars_list)[[user_coeff_choice]]",
                    description="Bootstrap bias for selected parameter"
                ),
                ValidateModuleFile(
                    name="bootstrap_standard_deviation",
                    path_dynamic=os.path.join(output_dir, "bootstrap/plots/coeff_sd_boot.html"),
                    path_static=os.path.join(output_dir, "bootstrap/plots/coeff_sd_boot.png"),
                    function="fun.plot.coeffboot.TEST(df.results.test, alpha=pars_alpha, matrix1='coeff.sd.boot', pars=pars_list)[[user_coeff_choice]]",
                    description="Bootstrap standard deviation for selected parameter"
                )
            ]
        )
        
        bootstrap_validation = BootstrapValidation(
            description="Bootstrap validation results for H-SDPD models (Model4_UHI, Model5_RAB, Model6_HSDPD_user)",
            bootstrap_comparison=bootstrap_comparison,
            parameter_distribution=parameter_distribution
        )
        
        return ValidateModuleOutputs(
            residual_summary_statistics=residual_summary_statistics,
            autocorrelation_tests=autocorrelation_tests,
            normality_tests=normality_tests,
            bootstrap_validation=bootstrap_validation
        )
