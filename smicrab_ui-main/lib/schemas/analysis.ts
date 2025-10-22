import { z } from "zod";
import { ModelType, SummaryStat, AnalysisVariable } from "@/types/enums";

// Schema for coordinates
export const coordinateSchema = z.object({
  user_longitude_choice: z.number().min(-180).max(180, "Longitude must be between -180 and 180"),
  user_latitude_choice: z.number().min(-90).max(90, "Latitude must be between -90 and 90"),
});

// Schema for date selection
export const dateSchema = z.object({
  user_date_choice: z.string().optional(),
});

// Schema for model configuration
export const modelConfigSchema = z.object({
  model_type: z.nativeEnum(ModelType),
  bool_update: z.boolean().default(true),
  bool_trend: z.boolean().default(true),
  bool_dynamic: z.boolean().default(true),
  user_coeff_choice: z.number().min(0, "Coefficient must be non-negative").default(1.0),
});

// Schema for variable selection
export const variableSchema = z.object({
  endogenous_variable: z.nativeEnum(AnalysisVariable),
  covariate_variables: z.array(z.nativeEnum(AnalysisVariable)),
  summary_stat: z.nativeEnum(SummaryStat),
});

// Schema for vector options
export const vectorOptionsSchema = z.object({
  groups: z.number().int().min(1, "Groups must be at least 1"),
  px_core: z.number().int().min(1, "Core pixels must be at least 1"),
  px_neighbors: z.number().int().min(1, "Neighbor pixels must be at least 1"),
  t_frequency: z.number().int().min(1, "Time frequency must be at least 1"),
  na_rm: z.boolean().default(true),
  NAcovs: z.string().min(1, "NA covariate handling method is required"),
});



// Base analysis form schema without validation
export const baseAnalysisFormSchema = z.object({
  ...coordinateSchema.shape,
  ...dateSchema.shape,
  ...modelConfigSchema.shape,
  ...variableSchema.shape,
  vec_options: vectorOptionsSchema,
});

// Complete analysis form schema with validation
export const analysisFormSchema = baseAnalysisFormSchema.refine(
  (data) => {
    // Ensure endogenous variable is not included in covariate variables
    return !data.covariate_variables.includes(data.endogenous_variable);
  },
  {
    message: "Endogenous variable cannot be included in covariate variables",
    path: ["covariate_variables"],
  }
);

// Schema for saving analysis parameters (API request)
export const saveAnalysisParametersSchema = z.object({
  analysis_id: z.string().uuid("Invalid analysis ID"),
  ...baseAnalysisFormSchema.shape,
});

// Type definitions
export type CoordinateFormData = z.infer<typeof coordinateSchema>;
export type DateFormData = z.infer<typeof dateSchema>;
export type ModelConfigFormData = z.infer<typeof modelConfigSchema>;
export type VariableFormData = z.infer<typeof variableSchema>;
export type VectorOptionsFormData = z.infer<typeof vectorOptionsSchema>;
export type AnalysisFormData = z.infer<typeof baseAnalysisFormSchema>;
export type SaveAnalysisParametersFormData = z.infer<typeof saveAnalysisParametersSchema>;

// Run Analysis Schema
export const runAnalysisSchema = z.object({
  analysis_id: z.string().uuid(),
  model_type: z.nativeEnum(ModelType),
});

// Create Analysis Schema
export const createAnalysisSchema = z.object({
  user_id: z.string().uuid(),
});

// Type exports
export type RunAnalysisInput = z.infer<typeof runAnalysisSchema>;
export type CreateAnalysisInput = z.infer<typeof createAnalysisSchema>; 