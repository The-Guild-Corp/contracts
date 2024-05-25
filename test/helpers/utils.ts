import { Log, Interface } from "ethers";

// Searches a specific event name, and returns the parsed object
// Does not work when there are multiple events with the same name
// Returns an empty object if the event is not found
export function parseEventLogs(
    logs: Log[],
    contractInterface: Interface,
    eventName: string,
    keys: string[]
) {
    const eventLog = logs.find(
        (log) => contractInterface.parseLog(log as any)?.name === eventName
    );

    const parsedObject: any = {};

    if (eventLog) {
        const parsedLog = contractInterface.parseLog(eventLog as any);
        if (parsedLog) {
            for (let i = 0; i < keys.length; i++) {
                parsedObject[keys[i]] = parsedLog.args[i];
            }
        }
    }

    return parsedObject;
}

export function calculateTaxAmount(amount: bigint, taxRate: bigint): bigint {
    const bigAmount = BigInt(amount);
    const bigTaxRate = BigInt(taxRate);
    return (bigAmount * bigTaxRate) / BigInt(10000);
}

// Timeout function
export function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
