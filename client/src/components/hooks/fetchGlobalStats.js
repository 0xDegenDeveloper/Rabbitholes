import { useState, useEffect } from "react";

export default function fetchGlobalStats() {
  const [globalStats, setGlobalStats] = useState({
    holes: 0,
    rabbits: 0,
    depth: 0,
    totalSupply: 0,
    digFee: 0,
    digReward: 0,
  });

  useEffect(() => {
    setGlobalStats({
      holes: 999,
      rabbits: 3333,
      depth: 8888,
      totalSupply: "12,3456.7",
      digFee: 0.001,
      digReward: "25.0",
    });
  }, []);

  /// make contract read

  return globalStats;
}
