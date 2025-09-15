import { onRequestPost as __api_waitlist_js_onRequestPost } from "C:\\Users\\admin\\Documents\\GEARSH\\gearsh_app\\web\\functions\\api\\waitlist.js"

export const routes = [
    {
      routePath: "/api/waitlist",
      mountPath: "/api",
      method: "POST",
      middlewares: [],
      modules: [__api_waitlist_js_onRequestPost],
    },
  ]