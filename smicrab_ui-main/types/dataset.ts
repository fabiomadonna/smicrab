export interface Dataset {
  id: string;
  name: string;
  variable_name: string;
  from_date: string;
  to_date: string;
  frequency: string;
  file_path: string;
  csv_file_path: string;
}