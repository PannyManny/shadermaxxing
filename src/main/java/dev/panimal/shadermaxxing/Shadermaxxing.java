package dev.panimal.shadermaxxing;

import dev.panimal.shadermaxxing.network.VFXSyncS2CPacket;
import dev.panimal.shadermaxxing.registry.Commands;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import net.minecraft.command.argument.BlockPosArgumentType;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.util.Identifier;
import net.minecraft.util.math.BlockPos;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collection;
import java.util.Optional;
import java.util.stream.Collectors;

public class Shadermaxxing implements ModInitializer {
    public static final String MOD_ID = "shadermaxxing";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    public static final Identifier CLIENT_SYNC_PACKET_ID = Identifier.of(MOD_ID, "shader_event");

    @Override
    public void onInitialize() {
        PayloadTypeRegistry.playS2C().register(VFXSyncS2CPacket.ID, VFXSyncS2CPacket.CODEC);

        CommandRegistrationCallback.EVENT.register(Commands::register);
    }
}