
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (
    RisingEdge, FallingEdge,
    Timer
)

async def test1(dut): #testing writing 1 thing then reading it
    dut.rst.value = 0
    #delay by both clocks to ensure both domains see the reset
    await RisingEdge(dut.wr_clk)
    await RisingEdge(dut.rd_clk)
    dut.rst.value = 1
    dut.i_data.value = 10
    dut.i_wr.value = 1
    await RisingEdge(dut.wr_clk)
    dut.i_wr.value = 0
    dut.i_data.value = 0

    await Timer(50, units="ns") #waiting

    dut.i_rd.value = 1
    await RisingEdge(dut.rd_clk)
    dut.i_rd.value = 0
    await RisingEdge(dut.rd_clk)
    x = dut.o_data.value
    assert x == 10


    await RisingEdge(dut.rd_clk) 
    assert dut.empty.value == 1
    dut.i_rd.value = 0
    dut.i_wr.value = 0

async def test2(dut): #more complete test testing full/empty status, writes 8 times then reads 8 times
    dut.rst.value = 0
    dut.i_rd.value = 0
    await RisingEdge(dut.wr_clk)
    await RisingEdge(dut.rd_clk)
    dut.i_wr.value = 1
    dut.rst.value = 1
    dut.i_data.value = 1
    await RisingEdge(dut.wr_clk)
    dut.i_data.value = 2
    await RisingEdge(dut.wr_clk)
    dut.i_data.value = 3
    await RisingEdge(dut.wr_clk)
    dut.i_data.value = 4
    await RisingEdge(dut.wr_clk)
    dut.i_data.value = 5
    await RisingEdge(dut.wr_clk)
    dut.i_data.value = 6
    await RisingEdge(dut.wr_clk)
    dut.i_data.value = 7
    await RisingEdge(dut.wr_clk)
    dut.i_data.value = 8
    await RisingEdge(dut.wr_clk)
    dut.i_wr.value = 0
    #done writing queue to make it full
    await RisingEdge(dut.rd_clk)
    await RisingEdge(dut.rd_clk)

    assert dut.full.value == 1

    #start reading from q
    dut.i_rd.value = 1
    await RisingEdge(dut.rd_clk)
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 1
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 2
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 3
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 4
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 5
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 6
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 7
    await RisingEdge(dut.rd_clk)
    assert dut.o_data.value == 8
    assert dut.empty.value == 1

async def test3(dut):
    #i was running out of time so chatgpt helped me write the simultaneous write and read test
    dut.rst.value = 0
    await RisingEdge(dut.wr_clk)
    await RisingEdge(dut.rd_clk)
    dut.rst.value = 1

    write_vals = list(range(20, 28))
    read_vals = []

    dut.i_wr.value = 0
    dut.i_rd.value = 0

    async def writer():
        for val in write_vals:
            while dut.full.value:
                await RisingEdge(dut.wr_clk)
            dut.i_data.value = val
            dut.i_wr.value = 1
            await RisingEdge(dut.wr_clk)
            dut.i_wr.value = 0
            await RisingEdge(dut.wr_clk)

    async def reader():
        while len(read_vals) < len(write_vals):
            if not dut.empty.value:
                dut.i_rd.value = 1
                await RisingEdge(dut.rd_clk)  # issue read
                await Timer(1, units="ns")    # short delay for stable o_data
                read_vals.append(int(dut.o_data.value))
                dut.i_rd.value = 0
            await RisingEdge(dut.rd_clk)

    writer_task = cocotb.start_soon(writer())
    reader_task = cocotb.start_soon(reader())

    await writer_task
    await reader_task
    
    assert read_vals == write_vals


@cocotb.test()
async def test(dut):
    
    cocotb.start_soon(Clock(dut.rd_clk, 13, units='ns').start())
    cocotb.start_soon(Clock(dut.wr_clk, 7, units='ns').start())

    await test1(dut)
    await Timer(50, units="ns")
    await test2(dut)
    await Timer(50, units="ns")
    await test3(dut)




