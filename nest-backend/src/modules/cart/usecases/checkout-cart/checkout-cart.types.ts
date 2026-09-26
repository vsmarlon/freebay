import { ReserveOrderInput } from "../../types/cart.types";

export type PlannedCartItem = ReserveOrderInput & { productTitle: string };
