"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Info, Database, Loader2 } from "lucide-react";
import { AnalysisFormData } from "@/types/analysis";
import { Dataset } from "@/types/dataset";
import { fetchRasters } from "@/actions/dataset.actions";

interface StepProps {
  formData: Partial<AnalysisFormData>;
  onNext: (data: Partial<AnalysisFormData>) => void;
  onPrevious?: () => void;
  isLoading?: boolean;
  errors?: Record<string, string>;
  isLastStep?: boolean;
  onSubmit?: (data: Partial<AnalysisFormData>) => void;
}


export function DataModuleStep({ formData, onNext, onPrevious, isLoading }: StepProps) {
  const [updateData, setUpdateData] = useState(formData.bool_update ?? true);

  const [datasets, setDatasets] = useState<Dataset[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDatasets();
  }, []);

  const loadDatasets = async () => {
    try {
      setLoading(true);
      const response = await fetchRasters();
      
      if (response.success) {
        setDatasets(response.data || []);
        setError(null);
      } else {
        setError(response.message || 'Failed to load datasets');
      }
    } catch (err) {
      setError('Failed to load datasets');
      console.error('Error loading datasets:', err);
    } finally {
      setLoading(false);
    }
  };
  const handleNext = () => {
    const stepData: Partial<AnalysisFormData> = {
      bool_update: updateData
    };
    onNext(stepData);
  };

  return (
    <div className="space-y-4">

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-lg">
            <Database className="w-4 h-4" />
            Available Datasets
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-3 border rounded-lg">
            <div>
              <Label htmlFor="bool_update" className="text-sm font-medium">
                Update Computation Results
              </Label>
              <p className="text-xs text-muted-foreground">
                Enable for updated results (slower) or disable for pre-computed data (faster)
              </p>
            </div>
            <Switch
              id="bool_update"
              checked={updateData}
              onCheckedChange={setUpdateData}
              disabled={true}
            />
          </div>

          <div className="space-y-2">
            <Label className="text-sm font-medium">Available Datasets (8 total)</Label>
            <div className="border rounded-lg">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Variable</TableHead>
                    <TableHead>Time Range</TableHead>
                    <TableHead>Frequency</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableRow>
                      <TableCell colSpan={4} className="text-center">
                        <div className="flex items-center justify-center gap-2">
                          <Loader2 className="w-4 h-4 animate-spin" /> Loading datasets...
                        </div>
                      </TableCell>
                    </TableRow>
                  ) : datasets.map((dataset) => (
                    <TableRow key={dataset.id}>
                      <TableCell className="text-sm text-muted-foreground">{dataset.variable_name}</TableCell>
                      <TableCell className="text-sm">{dataset.from_date} - {dataset.to_date}</TableCell>
                      <TableCell className="text-sm">{dataset.frequency}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
            <p className="text-xs text-muted-foreground">
              All datasets are automatically included in the analysis pipeline
            </p>
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-between">
        <Button
          variant="outline"
          onClick={onPrevious}
          disabled={!onPrevious || isLoading}
        >
          Previous
        </Button>
        <Button onClick={handleNext} disabled={isLoading}>
          Next: Describe Module
        </Button>
      </div>
    </div>
  );
} 