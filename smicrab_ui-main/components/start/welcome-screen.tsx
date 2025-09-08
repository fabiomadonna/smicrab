"use client";

import React from "react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import {
  Play,
  Database,
  BarChart3,
  CheckCircle,
  MapPin,
  ArrowRight,
  Clock,
  Settings,
  TrendingUp,
  FileText,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { CreateAnalysisButton } from "../analysis";

interface WelcomeScreenProps {
  userId: string;
}

export function WelcomeScreen({ userId }: WelcomeScreenProps) {
  const router = useRouter();
  const processSteps = [
    {
      id: 1,
      title: "Input Module",
      description: "Select time intervals and define model variables",
      icon: Database,
      details: [
        "Time interval selection",
        "Variable configuration",
        "Model definition",
      ],
    },
    {
      id: 2,
      title: "Estimate Module",
      description: "Process spatial-temporal data and build DataFrame",
      icon: Settings,
      details: ["Data processing", "SDPD calculations", "DataFrame generation"],
    },
    {
      id: 3,
      title: "Validate Module",
      description: "Verify results and validate model outputs",
      icon: CheckCircle,
      details: ["Data validation", "Quality checks", "Result confirmation"],
    },
    {
      id: 4,
      title: "Risk Map Module",
      description: "Generate visualizations and export results",
      icon: BarChart3,
      details: ["Statistical plots", "Time series analysis", "Risk mapping"],
    },
  ];

  const features = [
    {
      icon: Clock,
      title: "Time Series Analysis",
      description:
        "Analyze spatial-temporal patterns with advanced statistical methods",
    },
    {
      icon: MapPin,
      title: "Spatial Analysis",
      description:
        "Process raster data with pixel-level precision and spatial dependencies",
    },
    {
      icon: TrendingUp,
      title: "SDPD Modeling",
      description:
        "Implement Spatial Dynamic Panel Data models for robust analysis",
    },
    {
      icon: FileText,
      title: "Export & Visualization",
      description: "Generate publication-ready plots and exportable datasets",
    },
  ];

  return (
    <div className="min-h-screen">
      <div className="container mx-auto px-6 py-12">
        {/* Header Section */}
        <div className="text-center space-y-6 mb-12">
          <div className="space-y-4">
            <Badge variant="secondary" className="text-lg px-4 py-2">
              Spatial-Temporal Analysis Platform
            </Badge>
            <h1 className="text-6xl font-bold bg-gradient-to-r from-blue-500 to-indigo-500 bg-clip-text text-transparent">
              SMICRAB GUI
            </h1>
            <p className="text-2xl text-muted-foreground max-w-3xl mx-auto">
              Advanced Spatial-Temporal Data Analysis Interface for
              Environmental Research
            </p>
          </div>

          <div className="flex justify-center">
            <Badge variant="outline" className="text-base px-6 py-2">
              Powered by SDPD Package & R Statistical Computing
            </Badge>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
          {/* Key Features */}
          <Card className="shadow-lg">
            <CardHeader>
              <CardTitle className="text-2xl flex items-center gap-2">
                <CheckCircle className="h-6 w-6 text-green-500 dark:text-green-300" />
                Key Features
              </CardTitle>
              <CardDescription className="text-base">
                Comprehensive tools for spatial-temporal analysis
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 gap-4">
                {features.map((feature, index) => (
                  <div key={index} className="flex items-start gap-3">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                        <feature.icon className="h-4 w-4 text-blue-500 dark:text-blue-300" />
                      </div>
                    </div>
                    <div className="flex-1 min-w-0">
                      <h4 className="font-semibold text-sm">
                        {feature.title}
                      </h4>
                      <p className="text-xs text-muted-foreground">
                        {feature.description}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Process Flow */}
          <Card className="shadow-lg">
            <CardHeader>
              <CardTitle className="text-2xl flex items-center gap-2">
                <ArrowRight className="h-6 w-6 text-green-500 dark:text-green-300" />
                Analysis Process
              </CardTitle>
              <CardDescription className="text-base">
                Step-by-step workflow for your analysis
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {processSteps.map((step, index) => (
                  <div key={step.id} className="relative">
                    <div className="flex items-start gap-4">
                      <div className="flex-shrink-0">
                        <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                          <step.icon className="h-5 w-5 text-blue-500 dark:text-blue-300" />
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-semibold text-base">
                          {step.title}
                        </h4>
                        <p className="text-sm text-muted-foreground mb-2">
                          {step.description}
                        </p>
                        <div className="flex flex-wrap gap-1">
                          {step.details.map((detail, detailIndex) => (
                            <Badge
                              key={detailIndex}
                              variant="outline"
                              className="text-xs"
                            >
                              {detail}
                            </Badge>
                          ))}
                        </div>
                      </div>
                    </div>
                    {index < processSteps.length - 1 && (
                      <div className="absolute left-5 top-12 w-px h-8 bg-border"></div>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Getting Started Section */}
        <Card className="shadow-lg bg-gradient-to-r from-blue-500 to-indigo-500 text-white">
          <CardContent className="p-8">
            <div className="text-center space-y-6">
              <div className="space-y-4">
                <h2 className="text-3xl font-bold">
                  Ready to Begin Your Analysis?
                </h2>
                <p className="text-xl text-blue-100 max-w-2xl mx-auto">
                  Follow our guided workflow to process your spatial-temporal
                  data and generate comprehensive risk assessments with advanced
                  statistical modeling.
                </p>
              </div>

              <div className="space-y-4">
                <CreateAnalysisButton
                  userId={userId}
                  variant="default"
                  className="w-auto"
                  iconType="plus"
                >
                  New Analysis
                </CreateAnalysisButton>

                <p className="text-sm text-blue-200">
                  The process typically takes 5-10 minutes depending on data
                  complexity
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
