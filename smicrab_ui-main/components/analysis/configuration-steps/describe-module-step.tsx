"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Info,
  MapPin,
  TrendingUp,
  Calendar1Icon,
  CalendarIcon,
} from "lucide-react";
import { AnalysisFormData, SummaryStat } from "@/types/analysis";
import { Calendar } from "@/components/ui/calendar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogClose,
} from "@/components/ui/dialog";

import dynamic from "next/dynamic"; // Import next/dynamic

// import { MapSelector } from "@/components/ui/map-selector"; // Import the MapSelector component
// Dynamically import MapSelector with SSR disabled
const MapSelector = dynamic(
  () => import("@/components/ui/map-selector").then((mod) => mod.MapSelector),
  {
    ssr: false, // Disable server-side rendering
    loading: () => <div>Loading map...</div>, // Optional: Placeholder while loading
  }
);

interface StepProps {
  formData: Partial<AnalysisFormData>;
  onNext: (data: Partial<AnalysisFormData>) => void;
  onPrevious?: () => void;
  isLoading?: boolean;
  errors?: Record<string, string>;
}

const SUMMARY_STATISTICS = [
  { value: SummaryStat.MEAN, label: "Mean" },
  { value: SummaryStat.STANDARD_DEVIATION, label: "Standard Deviation" },
  { value: SummaryStat.MIN, label: "Minimum" },
  { value: SummaryStat.MAX, label: "Maximum" },
  { value: SummaryStat.MEDIAN, label: "Median" },
  { value: SummaryStat.RANGE, label: "Range" },
  { value: SummaryStat.COUNT_NAS, label: "Count NAs" },
];

export function DescribeModuleStep({
  formData,
  onNext,
  onPrevious,
  isLoading,
  errors,
}: StepProps) {
  const [longitude, setLongitude] = useState(
    formData.user_longitude_choice ?? 11.2
  );
  const [latitude, setLatitude] = useState(
    formData.user_latitude_choice ?? 45.1
  );
  const [dateChoice, setDateChoice] = useState(
    formData.user_date_choice ?? "2011-01-01"
  );
  const [summaryStat, setSummaryStat] = useState(
    formData.summary_stat ?? SummaryStat.MEAN
  );
  const [isMapOpen, setIsMapOpen] = useState(false); // State for map modal

  const handleNext = () => {
    const stepData: Partial<AnalysisFormData> = {
      user_longitude_choice: longitude,
      user_latitude_choice: latitude,
      user_date_choice: dateChoice,
      summary_stat: summaryStat,
    };
    onNext(stepData);
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-lg">Analysis Parameters</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="mb-8 grid grid-cols-1 md:grid-cols-8 lg:grid-cols-12 gap-x-4 gap-y-6">
            {/* Latitude Input */}
            <div className="space-y-2 cols-span-1 md:col-span-3 lg:col-span-5">
              <Label htmlFor="latitude" className="flex items-center gap-2">
                <MapPin className="w-4 h-4" />
                Latitude
              </Label>
              <div className="flex items-center gap-2">
                <Input
                  id="latitude"
                  type="number"
                  step="0.1"
                  min="32"
                  max="40"
                  value={latitude}
                  onChange={(e) => setLatitude(parseFloat(e.target.value))}
                  placeholder="45.1"
                  className={
                    errors?.user_latitude_choice ? "border-red-500" : ""
                  }
                />
              </div>
              {errors?.user_latitude_choice && (
                <p className="text-xs text-red-500">
                  {errors.user_latitude_choice}
                </p>
              )}
            </div>

            {/* Longitude Input */}
            <div className="space-y-2 col-span-1 md:col-span-3 lg:col-span-5">
              <Label htmlFor="longitude" className="flex items-center gap-2">
                <MapPin className="w-4 h-4" />
                Longitude
              </Label>
              <Input
                id="longitude"
                type="number"
                step="0.1"
                min="6"
                max="20"
                value={longitude}
                onChange={(e) => setLongitude(parseFloat(e.target.value))}
                placeholder="11.2"
                className={
                  errors?.user_longitude_choice ? "border-red-500" : ""
                }
              />
              {errors?.user_longitude_choice && (
                <p className="text-xs text-red-500">
                  {errors.user_longitude_choice}
                </p>
              )}
            </div>

            <Button
              variant="outline"
              className="col-span-1 md:col-span-2 self-end"
              onClick={() => setIsMapOpen(true)}
            >
              Select on Map
            </Button>

            {/* Other Inputs (Date and Summary Statistic) */}
            <div className="space-y-2 col-span-1 md:col-span-4 lg:col-span-6">
              <Label htmlFor="date_choice" className="flex items-center gap-2">
                <Calendar1Icon className="w-4 h-4" />
                Reference Date
              </Label>
              <DropdownMenu>
                <DropdownMenuTrigger className="w-full" asChild>
                  <Button
                    variant="outline"
                    className="w-full justify-between"
                    id="date_choice"
                  >
                    {dateChoice
                      ? new Date(dateChoice).toLocaleDateString()
                      : "Select Date"}
                    <CalendarIcon className="w-4 h-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent>
                  <Calendar
                    mode="single"
                    selected={dateChoice ? new Date(dateChoice) : undefined}
                    captionLayout="dropdown"
                    today={new Date("2011-01-01")}
                    startMonth={new Date(2011, 0, 1)}
                    endMonth={new Date(2023, 11, 31)}
                    onSelect={(date) =>
                      setDateChoice(date?.toISOString() ?? "")
                    }
                    className={errors?.user_date_choice ? "border-red-500" : ""}
                  />
                </DropdownMenuContent>
              </DropdownMenu>

              {errors?.user_date_choice && (
                <p className="text-xs text-red-500">
                  {errors.user_date_choice}
                </p>
              )}
            </div>

            <div className="space-y-2 col-span-1 md:col-span-4 lg:col-span-6">
              <Label htmlFor="summary_stat" className="flex items-center gap-2">
                <TrendingUp className="w-4 h-4" />
                Summary Statistic
              </Label>
              <Select
                value={summaryStat}
                onValueChange={(value) => setSummaryStat(value as SummaryStat)}
              >
                <SelectTrigger
                  id="summary_stat"
                  className={
                    errors?.summary_stat ? "border-red-500 w-full" : "w-full"
                  }
                >
                  <SelectValue placeholder="Select summary statistic" />
                </SelectTrigger>
                <SelectContent>
                  {SUMMARY_STATISTICS.map((stat) => (
                    <SelectItem key={stat.value} value={stat.value}>
                      {stat.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors?.summary_stat && (
                <p className="text-xs text-red-500">{errors.summary_stat}</p>
              )}
            </div>
          </div>

          <div className="p-3 bg-muted rounded-md text-sm">
            <p>
              <span className="font-medium ">Location:</span>{" "}
              {latitude.toFixed(2)}°N, {longitude.toFixed(2)}°E
            </p>
            <p>
              <span className="font-medium">Date:</span>{" "}
              {new Date(dateChoice).toLocaleDateString()}
            </p>
            <p>
              <span className="font-medium">Statistic:</span>{" "}
              {SUMMARY_STATISTICS.find((s) => s.value === summaryStat)?.label}
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Map Dialog */}
      {isMapOpen && (
        <Dialog open={isMapOpen} onOpenChange={setIsMapOpen}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle className="mt-6 flex justify-between items-center">
                <h4>Select location on map</h4>
                <span className="text-sm text-blue-600 dark:text-blue-400">
                  latitude={latitude} / longitude={longitude}
                </span>
              </DialogTitle>
            </DialogHeader>
            <MapSelector
              initialLatitude={latitude}
              initialLongitude={longitude}
              onSelect={(lat, lng) => {
                setLatitude(lat);
                setLongitude(lng);
              }}
            />
            <DialogClose asChild>
              <Button variant="outline">Close</Button>
            </DialogClose>
          </DialogContent>
        </Dialog>
      )}

      <div className="flex justify-between">
        <Button
          variant="outline"
          onClick={onPrevious}
          disabled={!onPrevious || isLoading}
        >
          Previous
        </Button>
        <Button onClick={handleNext} disabled={isLoading}>
          Next: Estimate Module
        </Button>
      </div>
    </div>
  );
}
