CAN_BUS = 1 --broadcast on CAN2 (0=CAN1, 1=CAN2)

TICK_RATE = 50
setTickRate(TICK_RATE)

TSIL_TIMEOUT_ENABLED = false

-- TSIL timeout in seconds
TSIL_TIMEOUT = 30

-- TSIL timeout in # of ticks
TSIL_TIMEOUT_TICKS = TSIL_TIMEOUT * TICK_RATE

-- ID of message to broadcast
BMS_CAN_ID = 0x6B2
WSPD_CAN_ID = 0x99

-- if message queue is full, blocks for x milliseconds
CAN_TIMEOUT = 10

-- Indices of IMD and BMS within the broadcast message
-- Lua is 1-indexed (pain)
BMS_INDEX = 2
IMD_INDEX = 1

-- Channel names
IMD_STATUS_NAME = "IMD_Status"
BMS_STATUS_NAME = "BMS_Status"
BMS_HEARTBEAT_NAME = "BMS_Heart"
PACK_POWER_NAME = "PackPower"
VCU_STATE_NAME  = "VCU_State"
FR_WSPD_NAME    = "FR_WSpeed"
FL_WSPD_NAME    = "FL_WSpeed"
BR_WSPD_NAME    = "BR_WSpeed"
BL_WSPD_NAME    = "BL_WSpeed"

MAX_POWER = 80

-- Messages to broadcast
bms_msg  = {0, 0, 0, 0, 0, 0, 0, 0}
wspd_msg = {0, 0, 0, 0, 0, 0, 0, 0}

-- most recent IMD and BMS values
stored_IMD = 1
stored_BMS = 1

timeout_counter = 0

opc_id = addChannel("OverPwrCnt", 50)
over_power_count = 0
currently_over_power = false

peak_power_id = addChannel("PeakPower", 50)
peak_power = 0

prev_BMS_Heart = 0

function pack_u16(value)
    local low = value % 256
    local high = math.floor(value / 256)
    return low, high
end

function onTick()

 -- reset on playing rtd sound
 local state = getChannel(VCU_STATE_NAME)
 if state ~= nil then
  if state == 1 then
   currently_over_power = false
   over_power_count = 0
   peak_power = 0
  end
 end

 local pwr = getChannel(PACK_POWER_NAME)
 if pwr ~= nil then
  -- check for over power
  if pwr >= MAX_POWER then
   if not currently_over_power then
    over_power_count = over_power_count + 1
   end
   currently_over_power = true
  else
   currently_over_power = false
  end

  --check for peak power
  if pwr > peak_power then
   peak_power = pwr
  end
 end
 setChannel(opc_id, over_power_count)
 setChannel(peak_power_id, peak_power)

 -- get imd/bms data and update stored_ variables if new data is available, keep them the same
 -- if new data is not available
 local imd = getChannel(IMD_STATUS_NAME)
 if imd ~= nil then
  stored_IMD = imd
 end


 -- bms and imd are sent in the same CAN message, so only
 -- update timeout for BMS
 local bms = getChannel(BMS_STATUS_NAME)
 if bms ~= nil then
     stored_BMS = bms
    end

 local bms_heart = getChannel(BMS_HEARTBEAT_NAME)

 if bms_heart ~= nil and bms_heart ~= prev_bms_heart then
		timeout_counter = 0
 elseif bms_heart ~= nil and bms_heart == prev_bms_heart then
        timeout_counter = timeout_counter + 1
 end
    
    prev_bms_heart = bms_heart

    -- included to stop overflow/unbounded growth of timeout counter
    -- (may be cause of memory issue)
    if (timeout_counter > TSIL_TIMEOUT_TICKS) then
      timeout_counter = TSIL_TIMEOUT_TICKS + 1
    end

    if TSIL_TIMEOUT_ENABLED and (timeout_counter > TSIL_TIMEOUT_TICKS) then
     stored_BMS = 0
     stored_IMD = 0
    end

    -- update CAN message
    bms_msg[IMD_INDEX] = stored_IMD  
    bms_msg[BMS_INDEX] = stored_BMS

    -- broadcast (0 = not extended)
    txCAN(CAN_BUS, BMS_CAN_ID, 0, bms_msg, CAN_TIMEOUT)

 local wspd = getChannel(FR_WSPD_NAME)
 if wspd ~= nil then wspd_msg[1], wspd_msg[2] = pack_u16(wspd) end
 wspd = getChannel(FL_WSPD_NAME)
 if wspd ~= nil then wspd_msg[3], wspd_msg[4] = pack_u16(wspd) end
 wspd = getChannel(BR_WSPD_NAME)
 if wspd ~= nil then wspd_msg[5], wspd_msg[6] = pack_u16(wspd) end
 wspd = getChannel(BL_WSPD_NAME)
 if wspd ~= nil then wspd_msg[7], wspd_msg[8] = pack_u16(wspd) end

 txCAN(CAN_BUS, WSPD_CAN_ID, 0, wspd_msg, CAN_TIMEOUT)
end
