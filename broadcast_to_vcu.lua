-- Tick rate, in Hz
TICK_RATE = 100

-- Channel to broadcast to VCU on (0 = CAN1, 1 = CAN2)
CAN_BUS = 1

-- ID of message to broadcast
BROADCAST_CAN_ID = 0x6B1

-- if message queue is full, blocks for x milliseconds
CAN_TIMEOUT = 10

-- Indices of IMD and BMS within the broadcast message
-- Lua is 1-indexed (pain)
BMS_INDEX = 1
IMD_INDEX = 2

-- Channel names for stored IMD and BMS status
IMD_CHANNEL = "IMD_Status"
BMS_CHANNEL = "BMS_Status"

-- Message to broadcast
msg = {0, 0, 0, 0, 0, 0, 0, 0}

-- most recent IMD and BMS values
stored_IMD = 1
stored_BMS = 1

temp = 0

setTickRate(TICK_RATE)
-- no InitCAN() needed because racecapture automatically does that

function onTick()
  -- get imd/bms data and update stored_ variables if new data is available, keep them the same
  -- if new data is not available
  temp = getChannel(IMD_CHANNEL)
  if temp ~= nil then
    stored_IMD = temp
  end

  temp = getChannel(BMS_CHANNEL)
  if temp ~= nil then
    stored_BMS = temp
  end

  -- update CAN message
  msg[IMD_INDEX] = stored_IMD  
  msg[BMS_INDEX] = stored_BMS


  -- broadcast (0 = not extended)
  txCAN(CAN_BUS, BROADCAST_CAN_ID, 0, msg, CAN_TIMEOUT)
    
end