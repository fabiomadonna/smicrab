import { API_URL } from "@/constants/constants";
import { AnalysisVariable } from "@/types/analysis";
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}


// Utility function to safely parse dates
export const safeParseDate = (dateString: string | undefined): Date | null => {
  if (!dateString) {
    console.warn('Date string is undefined or empty');
    return null;
  }

  try {
    const parsedDate = new Date(dateString);

    // Check if the date is valid
    if (isNaN(parsedDate.getTime())) {
      console.warn(`Invalid date: ${dateString}`);
      return null;
    }

    return parsedDate;
  } catch (error) {
    console.warn(`Error parsing date: ${dateString}`, error);
    return null;
  }
};

/**
 * Format date for display
 */
export function formatDateRange(fromDate: string, toDate: string): string {
  const from = new Date(fromDate).toLocaleDateString();
  const to = new Date(toDate).toLocaleDateString();
  return `${from} - ${to}`;
}


/**
 * Get download URL for a dataset
 */
export function getDatasetDownloadUrl(datasetId: string, format: 'netcdf' | 'csv'): string {
  return `${API_URL}/datasets/${datasetId}/download/${format}`;
}



export const getVariableDisplayName = (variable: AnalysisVariable): string => {
  const displayNames: Record<AnalysisVariable, string> = {
    [AnalysisVariable.MAXIMUM_AIR_TEMPERATURE_ADJUSTED]: "Max Air Temperature",
    [AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED]: "Mean Air Temperature", 
    [AnalysisVariable.MINIMUM_AIR_TEMPERATURE_ADJUSTED]: "Min Air Temperature",
    [AnalysisVariable.MEAN_RELATIVE_HUMIDITY_ADJUSTED]: "Mean Humidity",
    [AnalysisVariable.ACCUMULATED_PRECIPITATION_ADJUSTED]: "Precipitation",
    [AnalysisVariable.MEAN_WIND_SPEED_ADJUSTED]: "Mean Wind Speed",
    [AnalysisVariable.BLACK_SKY_ALBEDO_ALL_MEAN]: "Black Sky Albedo",
    [AnalysisVariable.LST_H18]: "Land Surface Temp",
  };
  return displayNames[variable] || variable;
};  