"use client";

import { Download, FileText } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { DescribeModuleStatistics } from "@/types/describe";
import Link from "next/link";

interface DescribeStatisticsDataProps {
  data: DescribeModuleStatistics;
  analysisId: string;
}

export function DescribeStatisticsData({ data, analysisId }: DescribeStatisticsDataProps) {

  const statisticsFiles = [
    {
      title: "Variable Summary Statistics",
      description: "JSON file containing summary statistics for all variables",
      path: data.variable_summary_statistics,
      icon: FileText,
      type: "JSON",
    },
    {
      title: "Pixel Time Series Data",
      description: "JSON file containing time series data for selected pixels",
      path: data.pixel_time_series_data,
      icon: FileText,
      type: "JSON",
    },
  ];

  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-2">
        {statisticsFiles.map((file, index) => {
          const Icon = file.icon;
          const filename = file.path.split('/').pop() || `statistics_${index + 1}`;
          
          return (
            <Card key={index} className="relative">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                    <Icon className="h-5 w-5 text-primary" />
                  </div>
                  <div className="flex-1">
                    <CardTitle className="text-base">{file.title}</CardTitle>
                    <CardDescription className="text-sm">
                      {file.description}
                    </CardDescription>
                  </div>
                  <div className="text-xs font-mono bg-muted px-2 py-1 rounded">
                    {file.type}
                  </div>
                </div>
              </CardHeader>
              <CardContent className="pt-0">
                <div className="flex items-center justify-between">
                  <div className="text-sm text-muted-foreground font-mono truncate">
                    {filename}
                  </div>
                  <Link href={file.path} target="_blank">
                    <Button
                      size="sm"
                      className="shrink-0"
                    >
                      <Download className="h-4 w-4 mr-2" />
                      Download
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <div className="text-sm text-muted-foreground bg-muted/50 p-4 rounded-lg">
        <div className="font-medium mb-2">Statistics Data Information:</div>
        <ul className="space-y-1 text-xs">
          <li>• JSON files contain structured data that can be used for further analysis</li>
          <li>• Variable summary statistics include mean, standard deviation, min, max values</li>
          <li>• Pixel time series data can be used for custom visualizations and analysis</li>
          <li>• Files are generated based on your analysis configuration and selected variables</li>
        </ul>
      </div>
    </div>
  );
} 