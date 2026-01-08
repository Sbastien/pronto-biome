// New file with various issues a junior dev might introduce

import fs from "fs";  // Wrong: Node.js import without node: protocol

// Unused variable
const DEBUG = true;

// Security issue: eval
export function trackEvent(eventName: string, data: Record<string, unknown>) {
  const payload = JSON.stringify({ event: eventName, data, timestamp: Date.now() });

  // Bad practice: eval for "dynamic" code
  eval(`console.log("Tracking: ${eventName}")`);

  // Pretend to send to server
  fetch("/api/analytics", {
    method: "POST",
    body: payload,
  });
}

// Duplicate switch case
export function getEventPriority(eventName: string): number {
  switch (eventName) {
    case "click":
      return 1;
    case "submit":
      return 2;
    case "click":  // Duplicate!
      return 3;
    default:
      return 0;
  }
}

// Constant condition
export function shouldTrack(): boolean {
  if (true) {
    return true;
  }
  return false;
}

// Comparison with NaN
export function isValidNumber(value: number): boolean {
  return value === NaN ? false : true;
}
