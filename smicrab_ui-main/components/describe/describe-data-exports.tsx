"use client";

import { Download, FileText, Database } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { DescribeModuleDataExports } from "@/types/describe";
import Link from "next/link";

interface DescribeDataExportsProps {
  data: DescribeModuleDataExports;
  analysisId: string;
}

export function DescribeDataExports({ data, analysisId }: DescribeDataExportsProps) {

  const exports = [
    {
      title: "Endogenous Variable CSV",
      description: "CSV file containing the endogenous variable data",
      path: data.endogenous_variable_csv,
      icon: FileText,
      type: "CSV",
    }
  ];


  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-1">
        {exports.map((exportItem, index) => {
          const Icon = exportItem.icon;
          const filename = exportItem.path.split('/').pop() || `export_${index + 1}`;
          
          return (
            <Card key={index} className="relative">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                    <Icon className="h-5 w-5 text-primary" />
                  </div>
                  <div className="flex-1">
                    <CardTitle className="text-base">{exportItem.title}</CardTitle>
                    <CardDescription className="text-sm">
                      {exportItem.description}
                    </CardDescription>
                  </div>
                  <div className="text-xs font-mono bg-muted px-2 py-1 rounded">
                    {exportItem.type}
                  </div>
                </div>
              </CardHeader>
              <CardContent className="pt-0">
                <div className="flex items-center justify-between">
                  <div className="text-sm text-muted-foreground font-mono truncate">
                    {filename}
                  </div>
                  <Link href={exportItem.path} target="_blank">
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
        <div className="font-medium mb-2">Export Information:</div>
        <ul className="space-y-1 text-xs">
          <li>• CSV files can be opened in Excel, R, Python, or any data analysis tool</li>
          <li>• RData files are specifically for R and contain all processed dataframes</li>
          <li>• Files are generated based on your analysis configuration and model type</li>
        </ul>
      </div>
    </div>
  );
} 