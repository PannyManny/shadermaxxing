package dev.panimal.shadermaxxing.client;

import dev.panimal.shadermaxxing.client.rendering.EventShader;
import dev.panimal.shadermaxxing.network.VFXSyncS2CPacket;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import net.minecraft.client.MinecraftClient;

public class ShadermaxxingClient implements ClientModInitializer {
    private static final Logger LOGGER = LoggerFactory.getLogger("shadermaxxing-client");

    @Override
    public void onInitializeClient() {
        ClientPlayNetworking.registerGlobalReceiver(VFXSyncS2CPacket.ID, (payload, context) -> {
            var pos = payload.pos();
            MinecraftClient client = MinecraftClient.getInstance();

            client.execute(() -> {
                EventShader.INSTANCE.blockPosition = pos.toCenterPos().toVector3f();
                EventShader.INSTANCE.dimension = client.world.getRegistryKey();
            });
        });

        ClientTickEvents.END_CLIENT_TICK.register(EventShader.INSTANCE);
        org.ladysnake.satin.api.event.PostWorldRenderCallback.EVENT.register(EventShader.INSTANCE);
    }
}
