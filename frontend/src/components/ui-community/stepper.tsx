"use client"

import { Check } from "lucide-react"
import { cn } from "@/lib/utils"

interface StepperProps {
  steps: string[]
  currentStep: number
  onStepClick?: (step: number) => void
  className?: string
}

export function Stepper({
  steps,
  currentStep,
  onStepClick,
  className,
}: StepperProps) {
  return (
    <div className={cn("flex w-full", className)}>
      {steps.map((step, index) => {
        const isActive = currentStep === index
        const isCompleted = currentStep > index
        const isLast = index === steps.length - 1

        return (
          <div
            key={index}
            className={cn(
              "flex items-center",
              isLast ? "flex-1" : "flex-1 relative"
            )}
          >
            <button
              type="button"
              className={cn(
                "flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 transition-colors duration-200",
                isActive
                  ? "border-primary bg-primary text-primary-foreground"
                  : isCompleted
                  ? "border-primary bg-primary text-primary-foreground"
                  : "border-border text-muted-foreground"
              )}
              onClick={() => onStepClick?.(index)}
              disabled={!onStepClick}
            >
              {isCompleted ? (
                <Check className="h-4 w-4" />
              ) : (
                <span>{index + 1}</span>
              )}
            </button>
            
            <div className="hidden sm:block ml-3">
              <p className={cn(
                "text-sm font-medium",
                isActive || isCompleted 
                  ? "text-foreground" 
                  : "text-muted-foreground"
              )}>
                {step}
              </p>
            </div>

            {!isLast && (
              <div
                className={cn(
                  "absolute right-0 top-4 h-[2px] w-[calc(100%-2rem)]",
                  isCompleted ? "bg-primary" : "bg-border"
                )}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}
