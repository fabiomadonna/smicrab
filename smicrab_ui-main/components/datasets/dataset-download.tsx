"use client";

import React, { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Download, FileText, Database, AlertCircle } from "lucide-react";
import { formatDateRange } from "@/lib/utils";
import { fetchRasters } from "@/actions/dataset.actions";
import { Dataset } from "@/types/dataset";
import {
  Table,
  TableHeader,
  TableBody,
  TableCell,
  TableRow,
  TableHead,
} from "@/components/ui/table";
import Link from "next/link";

export function DatasetDownload() {
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
        setError(response.message || "Failed to load datasets");
      }
    } catch (err) {
      setError("Failed to load datasets");
      console.error("Error loading datasets:", err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-3 p-4 pt-6">
      <div className="flex items-center justify-start gap-2">
        <Database className="h-5 w-5" />
        <h3 className="text-2xl font-semibold">Datasets</h3>
      </div>

      {loading && (
        <div className="p-3 pt-6 overflow-y-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Date Range</TableHead>
                <TableHead>Frequency</TableHead>
                <TableHead>Variable</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {[1, 2, 3].map((_, index) => (
                <TableRow key={index}>
                  <TableCell>
                    <div className="animate-pulse h-4 bg-muted rounded w-3/4"></div>
                  </TableCell>
                  <TableCell>
                    <div className="animate-pulse h-4 bg-muted rounded w-1/2"></div>
                  </TableCell>
                  <TableCell>
                    <div className="animate-pulse h-4 bg-muted rounded w-1/3"></div>
                  </TableCell>
                  <TableCell>
                    <div className="animate-pulse h-4 bg-muted rounded w-1/3"></div>
                  </TableCell>
                  <TableCell>
                    <div className="flex space-x-1">
                      <div className="animate-pulse h-7 bg-muted rounded w-16"></div>
                      <div className="animate-pulse h-7 bg-muted rounded w-16"></div>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {error && (
        <Card className="border-destructive">
          <CardContent className="p-3">
            <div className="flex items-center space-x-2">
              <AlertCircle className="h-4 w-4 text-destructive" />
              <p className="text-xs text-destructive">{error}</p>
            </div>
          </CardContent>
        </Card>
      )}

      {!loading && !error && datasets.length === 0 && (
        <Card>
          <CardContent className="p-3">
            <p className="text-xs text-muted-foreground text-center">
              No datasets available
            </p>
          </CardContent>
        </Card>
      )}

      {!loading && !error && datasets.length > 0 && (
        <div className="pt-6 overflow-y-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Date Range</TableHead>
                <TableHead>Frequency</TableHead>
                <TableHead>Variable</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {datasets.map((dataset) => (
                <TableRow key={dataset.id}>
                  <TableCell className="font-medium truncate max-w-[150px]">
                    {dataset.name}
                  </TableCell>
                  <TableCell>
                    {formatDateRange(dataset.from_date, dataset.to_date)}
                  </TableCell>
                  <TableCell>
                    <Badge variant="secondary" className="text-xs">
                      {dataset.frequency}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className="text-xs">
                      {dataset.variable_name}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex space-x-2">
                      <Link href={dataset.file_path} target="_blank" prefetch={false}>
                        <Button
                          variant="outline"
                          size="sm"
                          className="h-7 text-xs"
                        >
                          <FileText className="h-3 w-3 mr-1" />
                          NetCDF
                        </Button>
                      </Link>
                      <Link href={dataset.csv_file_path.replace("_adjusted", "")} target="_blank" prefetch={false}>
                        <Button
                          variant="outline"
                          size="sm"
                          className="h-7 text-xs"
                        >
                          <Download className="h-3 w-3 mr-1" />
                          CSV
                        </Button>
                      </Link>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
