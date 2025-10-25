package dev.panimal.shadermaxxing.network;

import net.minecraft.network.PacketByteBuf;
import net.minecraft.network.codec.PacketCodec;
import net.minecraft.network.packet.CustomPayload;
import net.minecraft.util.Identifier;
import net.minecraft.util.math.BlockPos;

public record VFXSyncS2CPacket(BlockPos pos) implements CustomPayload {
    public static final CustomPayload.Id<VFXSyncS2CPacket> ID =
            new CustomPayload.Id<>(Identifier.of("shadermaxxing", "vfx_sync"));

    public static final PacketCodec<PacketByteBuf, VFXSyncS2CPacket> CODEC =
            PacketCodec.of(
                    (packet, buf) -> buf.writeBlockPos(packet.pos),
                    buf -> new VFXSyncS2CPacket(buf.readBlockPos())
            );

    @Override
    public CustomPayload.Id<? extends CustomPayload> getId() {
        return ID;
    }
}
