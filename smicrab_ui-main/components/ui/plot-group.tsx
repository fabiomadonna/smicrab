"use client";

import { useState } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Download } from "lucide-react";

interface PlotFile {
  name: string;
  path_dynamic?: string;
  path_static?: string;
  function?: string;
  description?: string;
  variable?: string; // For describe module compatibility
}

interface PlotGroupProps {
  title?: string;
  description?: string;
  files: PlotFile[];
  analysisId: string;
  isDynamic: boolean;
  getDisplayName?: (name: string) => string; // Function to format display names
  showFunctionInfo?: boolean;
  className?: string;
}

export function PlotGroup({
  files,
  analysisId,
  isDynamic,
  getDisplayName,
  showFunctionInfo = false,
  className = "",
}: PlotGroupProps) {
  const [activeFile, setActiveFile] = useState(
    files[0]?.name || files[0]?.variable || ""
  );

  const formatDisplayName = (file: PlotFile): string => {
    if (getDisplayName) {
      return getDisplayName(file.name || file.variable || "");
    }
    // Default formatting: replace underscores with spaces and capitalize
    const name = file.name || file.variable || "";
    return name
      .replace(/_/g, " ")
      .replace(/\b\w/g, (l: string) => l.toUpperCase());
  };

  const getFileKey = (file: PlotFile): string => {
    return file.name || file.variable || "";
  };

  const handleDownload = (path: string) => {
    const downloadUrl = path;
    window.open(downloadUrl, "_blank");
  };

  if (!files || files.length === 0) {
    return (
      <div className={`text-center text-muted-foreground py-8 ${className}`}>
        No plots available for this section.
      </div>
    );
  }

  const renderContent = (file: PlotFile) => {
    if (isDynamic && file.path_dynamic) {
      const iframeUrl = file.path_dynamic;
      return (
        <div className="rounded-lg overflow-hidden bg-white p-4 max-w-[860px] mx-auto">
          <iframe
            src={iframeUrl}
            className="w-full h-[560px] border-0"
            title={`${formatDisplayName(file)} - Interactive Plot`}
            sandbox="allow-scripts allow-same-origin"
          />
        </div>
      );
    } else if (file.path_static) {
      // For CSV files, show download button
      if (file.path_static.endsWith(".csv")) {
        return (
          <div className="flex flex-col items-center justify-center py-8 space-y-4">
            <p className="text-sm text-muted-foreground text-center">
              {file.description || "CSV data file"}
            </p>
            <Button
              onClick={() => handleDownload(file.path_static!)}
              variant="outline"
              className="flex items-center space-x-2"
            >
              <Download className="h-4 w-4" />
              <span>Download CSV</span>
            </Button>
          </div>
        );
      } else if (file.path_static.endsWith(".html")) {
        const iframeUrl = file.path_static;
        return (
          <div className="rounded-lg overflow-hidden bg-white p-4 w-full mx-auto h-[600px]">
          <iframe
            src={iframeUrl}
            className="w-full h-full border-0"
            title={`${formatDisplayName(file)} - Table`}
            sandbox="allow-scripts allow-same-origin"
          />
        </div>
        );
      } else {
        // For PNG images, show the image
        const imageUrl = file.path_static;
        return (
          <div className="space-y-2">
            <div className="border rounded-lg overflow-hidden bg-white p-4 max-w-[860px] mx-auto h-[600px]">
              <div className="flex items-center justify-center p-4">
                <img
                  src={imageUrl}
                  alt={`${formatDisplayName(file)} - Static Plot`}
                  className="max-w-full h-auto"
                  style={{ maxHeight: "600px", minHeight: "400px" }}
                />
              </div>
            </div>
            {file.path_static.endsWith(".png") && (
              <div className="flex justify-end">
                <Button
                  onClick={() => handleDownload(file.path_static!)}
                  variant="outline"
                  size="sm"
                  className="flex items-center space-x-1"
                >
                  <Download className="h-3 w-3" />
                  <span>Download</span>
                </Button>
              </div>
            )}
          </div>
        );
      }
    }

    return (
      <div className="flex items-center justify-center py-8">
        <p className="text-sm text-muted-foreground">No content available</p>
      </div>
    );
  };

  // Single file - no tabs needed
  if (files.length === 1) {
    const file = files[0];
    return (
      <div className={`space-y-4 ${className}`}>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-lg">
                  {formatDisplayName(file)}
                </CardTitle>
                {file.description && (
                  <CardDescription>{file.description}</CardDescription>
                )}
              </div>
              <div className="flex space-x-2">
                <Badge variant="outline">
                  {isDynamic
                    ? file.path_dynamic?.split(".").pop()?.toUpperCase() ||
                      "Interactive"
                    : file.path_static?.split(".").pop()?.toUpperCase() ||
                      "Static"}
                </Badge>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {renderContent(file)}

            {/* R Function Information */}
            {showFunctionInfo && file.function && (
              <div className="mt-4 text-xs text-muted-foreground bg-muted/50 p-3 rounded-lg">
                <div className="font-medium mb-1">R Function Used:</div>
                <code className="text-xs break-all">{file.function}</code>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    );
  }

  // Multiple files - use tabs
  return (
    <div className={`space-y-4 ${className}`}>
      <Tabs value={activeFile} onValueChange={setActiveFile} className="w-full">
        <TabsList className="flex flex-wrap h-auto p-1 bg-muted rounded-lg">
          {files.map((file) => (
            <TabsTrigger
              key={getFileKey(file)}
              value={getFileKey(file)}
              className="text-xs px-3 py-1 m-0.5"
              title={formatDisplayName(file)}
            >
              {formatDisplayName(file)}
            </TabsTrigger>
          ))}
        </TabsList>

        {files.map((file) => (
          <TabsContent
            key={getFileKey(file)}
            value={getFileKey(file)}
            className="mt-6"
          >
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="text-lg">
                      {formatDisplayName(file)}
                    </CardTitle>
                    {file.description && (
                      <CardDescription>{file.description}</CardDescription>
                    )}
                  </div>
                  <div className="flex space-x-2">
                    {isDynamic && file.path_dynamic && (
                      <Badge variant="secondary">Interactive</Badge>
                    )}
                    <Badge variant="outline">
                      {isDynamic
                        ? file.path_dynamic?.split(".").pop()?.toUpperCase()
                        : file.path_static?.split(".").pop()?.toUpperCase()}
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                {renderContent(file)}
                {/* R Function Information */}
                {showFunctionInfo && file.function && (
                  <div className="mt-4 text-xs text-muted-foreground bg-muted/50 p-3 rounded-lg">
                    <div className="font-medium mb-1">R Function Used:</div>
                    <code className="text-xs break-all">{file.function}</code>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}
