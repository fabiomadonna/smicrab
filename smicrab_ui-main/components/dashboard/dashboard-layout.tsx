"use client";

import React, { useState } from 'react';
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { 
  CheckCircle, 
  Settings, 
  BarChart3, 
  Home,
  Clock,
  Menu,
  ChevronLeft,
  ChevronRight,
  Database,
  LucideIcon
} from "lucide-react";

export type WorkflowStep = 
  | 'start' 
  | 'configure'
  | 'describe_module' 
  | 'estimate_module' 
  | 'validate_module' 
  | 'risk_map_module' 
  | 'end';

interface DashboardLayoutProps {
  currentStep: WorkflowStep;
  onStepChange: (step: WorkflowStep) => void;
  children: React.ReactNode;
  isLoading?: boolean;
}

type StepType = {
  id: WorkflowStep,
  title: string,
  icon: LucideIcon,
  description: string,
  completed: boolean
}

export function DashboardLayout({ currentStep, onStepChange, children, isLoading = false }: DashboardLayoutProps) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const steps: StepType[] = [
    { 
      id: 'start', 
      title: 'Getting Started', 
      icon: Home, 
      description: 'Project overview and introduction',
      completed: currentStep !== 'start'
    },
    { 
      id: 'configure', 
      title: 'Configuration', 
      icon: Settings, 
      description: 'Analysis parameters and setup',
      completed: ['describe_module', 'estimate_module', 'validate_module', 'risk_map_module', 'end'].includes(currentStep)
    },
    { 
      id: 'describe_module', 
      title: 'Describe Module', 
      icon: Database, 
      description: 'Data exploration and statistics',
      completed: ['estimate_module', 'validate_module', 'risk_map_module', 'end'].includes(currentStep)
    },
    { 
      id: 'estimate_module', 
      title: 'Estimate Module', 
      icon: CheckCircle, 
      description: 'Model estimation and analysis',
      completed: ['validate_module', 'risk_map_module', 'end'].includes(currentStep)
    },
    { 
      id: 'validate_module', 
      title: 'Validate Module', 
      icon: CheckCircle, 
      description: 'Model validation and quality checks',
      completed: ['risk_map_module', 'end'].includes(currentStep)
    },
    { 
      id: 'risk_map_module', 
      title: 'Risk Map Module', 
      icon: BarChart3, 
      description: 'Visualization and risk mapping',
      completed: currentStep === 'end'
    }
  ];

  const currentStepIndex = steps.findIndex(step => step.id === currentStep);
  const progressPercentage = currentStep === 'end' ? 100 : (currentStepIndex / (steps.length - 1)) * 100;

  const canGoNext = currentStep !== 'end';
  const canGoPrevious = currentStep !== 'start';

  const handleNextStep = () => {
    const stepOrder: WorkflowStep[] = ['start', 'configure', 'describe_module', 'estimate_module', 'validate_module', 'risk_map_module', 'end'];
    const currentIndex = stepOrder.indexOf(currentStep);
    if (currentIndex < stepOrder.length - 1) {
      onStepChange(stepOrder[currentIndex + 1]);
    }
  };

  const handlePreviousStep = () => {
    const stepOrder: WorkflowStep[] = ['start', 'configure', 'describe_module', 'estimate_module', 'validate_module', 'risk_map_module', 'end'];
    const currentIndex = stepOrder.indexOf(currentStep);
    if (currentIndex > 0) {
      onStepChange(stepOrder[currentIndex - 1]);
    }
  };

  const Sidebar = () => (
    <div className="w-full h-full border-r">
      <div className="p-6 space-y-6">
        {/* Logo Section */}
        <div className="space-y-2">
          <h2 className="text-2xl font-bold bg-gradient-to-r from-primary to-primary/80 bg-clip-text text-transparent">
            SMICRAB
          </h2>
          <p className="text-sm text-muted-foreground">
            Spatial-Temporal Analysis Platform
          </p>
        </div>

        <Separator />

        {/* Progress Overview */}
        <div className="space-y-4">
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Analysis Progress</span>
              <span className="text-sm text-muted-foreground">{Math.round(progressPercentage)}%</span>
            </div>
            <Progress value={progressPercentage} className="h-2" />
          </div>
          
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Clock className="h-4 w-4" />
            <span>
              {currentStep === 'start' ? 'Ready to begin' : 
               currentStep === 'configure' ? 'Configuration needed' :
               currentStep === 'end' ? 'Analysis complete' :
               'In progress...'}
            </span>
          </div>
        </div>

        <Separator />

        {/* Navigation Steps */}
        <div className="space-y-2">
          <h3 className="text-sm font-medium text-muted-foreground uppercase tracking-wider">
            Workflow Steps
          </h3>
          <nav className="space-y-1">
            {steps.map((step, index) => {
              const isActive = step.id === currentStep;
              const isCompleted = step.completed;
              const isAccessible = index <= currentStepIndex || isCompleted;

              return (
                <button
                  key={step.id}
                  onClick={() => isAccessible && onStepChange(step.id)}
                  disabled={!isAccessible}
                  className={`
                    w-full flex items-start gap-3 p-3 rounded-lg text-left transition-all duration-200
                    ${isActive 
                      ? 'bg-primary/10 border border-primary/20' 
                      : 'hover:bg-accent'
                    }
                    ${!isAccessible ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer'}
                  `}
                >
                  <div className={`
                    flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center
                    ${isActive 
                      ? 'bg-primary text-primary-foreground' 
                      : isCompleted 
                        ? 'bg-green-500 text-white'
                        : 'bg-muted text-muted-foreground'
                    }
                  `}>
                    {isCompleted ? (
                      <CheckCircle className="h-4 w-4" />
                    ) : (
                      <step.icon className="h-4 w-4" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className={`font-medium text-sm ${isActive ? 'text-primary' : ''}`}>
                      {step.title}
                    </h4>
                    <p className={`text-xs ${isActive ? 'text-primary/70' : 'text-muted-foreground'}`}>
                      {step.description}
                    </p>
                  </div>
                </button>
              );
            })}
          </nav>
        </div>

        <Separator />

        {/* Quick Stats */}
        <div className="space-y-3">
          <h3 className="text-sm font-medium text-muted-foreground uppercase tracking-wider">
            Session Info
          </h3>
          <div className="grid grid-cols-1 gap-2">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Started</span>
              <Badge variant="outline" className="text-xs">
                {new Date().toLocaleDateString()}
              </Badge>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Step {currentStepIndex + 1} of {steps.length}</span>
              <Badge variant="secondary" className="text-xs">
                {steps[currentStepIndex]?.title || 'Complete'}
              </Badge>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen flex">
      {/* Desktop Sidebar */}
      <div className="hidden lg:block w-80 flex-shrink-0">
        <div className="h-screen sticky top-0">
          <Sidebar />
        </div>
      </div>

      {/* Mobile Sidebar */}
      <Sheet open={isSidebarOpen} onOpenChange={setIsSidebarOpen}>
        <SheetTrigger asChild>
          <Button
            variant="outline"
            size="icon"
            className="lg:hidden fixed top-4 left-4 z-40 shadow-lg"
          >
            <Menu className="h-4 w-4" />
          </Button>
        </SheetTrigger>
        <SheetContent side="left" className="w-80 p-0">
          <Sidebar />
        </SheetContent>
      </Sheet>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="flex h-16 items-center px-6">
            <div className="flex items-center space-x-4 flex-1">
              <div className="space-y-1">
                <h1 className="text-xl font-semibold">
                  {steps.find(step => step.id === currentStep)?.title || 'SMICRAB Analysis'}
                </h1>
                <p className="text-sm text-muted-foreground">
                  {steps.find(step => step.id === currentStep)?.description || 'Spatial-Temporal Data Analysis'}
                </p>
              </div>
            </div>

            {/* Navigation Controls */}
            <div className="flex items-center space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handlePreviousStep}
                disabled={!canGoPrevious || isLoading}
              >
                <ChevronLeft className="h-4 w-4 mr-1" />
                Previous
              </Button>
              <Button
                size="sm"
                onClick={handleNextStep}
                disabled={!canGoNext || isLoading}
              >
                Next
                <ChevronRight className="h-4 w-4 ml-1" />
              </Button>
            </div>
          </div>
        </div>

        {/* Content */}
        <main className="flex-1 p-6">
          {isLoading ? (
            <div className="flex items-center justify-center h-64">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : (
            children
          )}
        </main>
      </div>
    </div>
  );
} 